// backend/routes/admin.js
const express = require('express');
const router = express.Router();
const User = require('../model/User');
const Attendance = require('../model/Attendance');
const isAdmin = require('../middleware/isAdmin');
const { sendNotificationToUser } = require('../services/notificationService'); // Adjust path if needed

// Protect all routes in this file with the isAdmin middleware
router.use(isAdmin);

// --- Instructor Management ---

// GET all instructors with their status (pending, approved, etc.)
router.get('/instructors', async (req, res) => {
  try {
    const instructors = await User.find({ role: 'instructor' }).sort({ createdAt: -1 });
    res.json({ success: true, data: instructors });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error' });
  }
});

// PUT to update an instructor's status (approve, reject, suspend)
router.put('/instructors/:id/status', async (req, res) => {
  const { status } = req.body;
  const validStatuses = ['approved', 'rejected', 'suspended', 'pending'];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ success: false, message: 'Invalid status' });
  }

  try {
    const instructor = await User.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true }
    );
    if (!instructor) {
      return res.status(404).json({ success: false, message: 'Instructor not found' });
    }
    // --- Send Notification to Instructor ---
  try {
    let title = 'Account Status Update';
    let body = `Your instructor account status has been updated to ${status}.`;

    // Customize messages for specific statuses
    if (status === 'approved') {
      title = 'Account Approved!';
      body = 'Congratulations! Your instructor account has been approved. You can now create groups.';
    } else if (status === 'rejected') {
      title = 'Account Update';
      body = 'There was an update regarding your instructor application. Please contact admin for details.'; // Keep it vague or add reason if available
    } else if (status === 'suspended') {
      title = 'Account Suspended';
      body = 'Your instructor account has been temporarily suspended. Please contact admin.';
    }

    // Send the notification using the instructor's ID from the updated document
    await sendNotificationToUser(instructor.id, title, body, { type: 'status_update', newStatus: status });

  } catch (notificationError) {
    // Log the error but don't fail the main request if notification fails
    console.error(`Failed to send status update notification to instructor ${instructor.id}:`, notificationError);
  }
  // --- End Notification ---
    res.json({ success: true, message: `Instructor status updated to ${status}`, data: instructor });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Server Error' });
  }
});

// DELETE an instructor
router.delete('/instructors/:id', async (req, res) => {
    try {
        const instructor = await User.findByIdAndDelete(req.params.id);
        if (!instructor) {
            return res.status(404).json({ success: false, message: 'Instructor not found' });
        }
        // You might also want to delete their groups, etc. (cascading delete)
        res.json({ success: true, message: 'Instructor successfully removed.' });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Server Error' });
    }
});

// --- Dashboard Statistics ---
router.get('/stats', async (req, res) => {
    console.log('[Admin Route /stats] Handler reached.');
    console.log('[Admin Route /stats] Authenticated User:', req.user ? req.user.email : 'No user attached!');

    try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        // --- THIS IS THE LOGIC YOU WERE MISSING ---
        const totalParticipants = await User.countDocuments({ role: 'participant' });
        const totalInstructors = await User.countDocuments({ role: 'instructor', status: 'approved' });
        const sessionsToday = await Attendance.countDocuments({ marked_at: { $gte: today } });
        const totalAttendance = await Attendance.countDocuments();
        // -------------------------------------------

        // Send the data back in the correct structure
        res.json({
            success: true,
            data: {
                totalParticipants,
                totalInstructors,
                sessionsToday,
                totalAttendance
            }
        });
    } catch (error) {
        console.error('[Admin Route /stats] Error:', error);
        res.status(500).json({ success: false, message: 'Failed to fetch stats' });
    }
});

router.get('/stats/attendance-over-time', async (req, res) => {
  try {
    const period = parseInt(req.query.period || 30); // Get period from query, default to 30 days

    // 1. Calculate the start date
    const startDate = new Date();
    startDate.setHours(0, 0, 0, 0); // Set to midnight
    startDate.setDate(startDate.getDate() - (period - 1)); // Go back (period - 1) days

    // 2. Run the aggregation pipeline
    const results = await Attendance.aggregate([
      {
        // Find all attendance records from the start date until now
        $match: {
          marked_at: { $gte: startDate }
        }
      },
      {
        // Group by the date part of 'marked_at' (in your server's local timezone)
        $group: {
          _id: { $dateToString: { format: "%Y-%m-%d", date: "$marked_at" } },
          attendance: { $sum: 1 }
        }
      },
      {
        // Sort by date ascending
        $sort: { _id: 1 }
      }
    ]);

    // 3. Create a lookup map for fast processing
    const dbResultsMap = new Map(results.map(r => [r._id, r.attendance]));

    // 4. Create a complete array for the last 'period' days
    const finalData = [];
    for (let i = 0; i < period; i++) {
      const date = new Date(startDate);
      date.setDate(date.getDate() + i);

      // "YYYY-MM-DD" format for map lookup
      const dateKey = date.toISOString().split('T')[0]; 
      // "Mon DD" format for the frontend chart (as requested)
      const dateLabel = date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });

      finalData.push({
        date: dateLabel,
        attendance: dbResultsMap.get(dateKey) || 0 // Use 0 if no data for that day
      });
    }

    res.json({ success: true, data: finalData });

  } catch (error) {
    console.error('Error fetching attendance-over-time:', error);
    res.status(500).json({ success: false, message: 'Server Error' });
  }
});

// --- NEW: Endpoint for Recent Activity Feed ---
router.get('/activity-feed', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit || 7);

    // 1. Fetch recent user registrations
    const registrations = await User.find({ role: 'participant' })
      .sort({ createdAt: -1 })
      .limit(limit)
      .select('firstName lastName createdAt')
      .lean(); // .lean() for faster, plain JS objects

    // 2. Fetch recent instructor approvals
    // Note: This relies on 'updatedAt'. A better schema might have a statusLog.
    const approvals = await User.find({ role: 'instructor', status: 'approved' })
      .sort({ updatedAt: -1 })
      .limit(limit)
      .select('firstName lastName updatedAt')
      .lean();

    // 3. Fetch recent session completions (using Attendance records)
    // We need to populate the group name and instructor name
    const sessions = await Attendance.find()
      .sort({ marked_at: -1 })
      .limit(limit)
      .populate({
        path: 'group_id',
        select: 'group_name instructor_id',
        populate: {
          path: 'instructor_id',
          select: 'firstName lastName'
        }
      })
      .select('group_id marked_at')
      .lean();
    
    // 4. Map all results into the standardized feed format
    const registrationFeed = registrations.map(u => ({
      id: u._id.toString() + '_user',
      type: 'USER_REGISTERED',
      timestamp: u.createdAt,
      details: {
        name: `${u.firstName} ${u.lastName}`
      }
    }));

    const approvalFeed = approvals.map(i => ({
      id: i._id.toString() + '_instructor',
      type: 'INSTRUCTOR_APPROVED',
      timestamp: i.updatedAt,
      details: {
        name: `${i.firstName} ${i.lastName}`
      }
    }));

    const sessionFeed = sessions.map(s => ({
      id: s._id.toString() + '_session',
      type: 'SESSION_COMPLETED',
      timestamp: s.marked_at,
      details: {
        groupName: s.group_id?.group_name || 'Unknown Group',
        instructorName: `${s.group_id?.instructor_id?.firstName || 'N/A'} ${s.group_id?.instructor_id?.lastName || ''}`
      }
    }));

    // 5. Combine, sort by timestamp, and slice to the limit
    const combinedFeed = [...registrationFeed, ...approvalFeed, ...sessionFeed];
    
    combinedFeed.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    const finalFeed = combinedFeed.slice(0, limit);

    res.json({ success: true, data: finalFeed });

  } catch (error) {
    console.error('Error fetching activity feed:', error);
    res.status(500).json({ success: false, message: 'Server Error' });
  }
});

router.get('/stats/top-groups', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit || 5); // Get top 5 by default

    // 1. Calculate the start date (7 days ago)
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - 7);
    startDate.setHours(0, 0, 0, 0);

    // 2. Run the aggregation pipeline
    const topGroups = await Attendance.aggregate([
      {
        // Filter records for the last 7 days
        $match: {
          marked_at: { $gte: startDate }
        }
      },
      {
        // Group by group_id and count the attendance for each
        $group: {
          _id: "$group_id",
          attendanceCount: { $sum: 1 }
        }
      },
      {
        // Sort by the count in descending order
        $sort: { attendanceCount: -1 }
      },
      {
        // Take only the top 'limit'
        $limit: limit
      },
      {
        // Join with the 'groups' collection to get group details
        $lookup: {
          from: 'groups', // This is the collection name Mongoose creates
          localField: '_id',
          foreignField: '_id',
          as: 'groupDetails'
        }
      },
      {
        // Deconstruct the 'groupDetails' array (it will have 0 or 1 element)
        $unwind: { path: "$groupDetails", preserveNullAndEmptyArrays: true }
      },
      {
        // Format the final output to match the frontend
        $project: {
          _id: 0, // Exclude the default _id
          id: "$_id", // Send the group's ID
          name: "$groupDetails.group_name", // Get the name from the joined details
          attendanceCount: 1 // Pass through the count
        }
      }
    ]);

    // Filter out any groups that might have been deleted but still had attendance
    const finalTopGroups = topGroups.filter(g => g.name);

    res.json({ success: true, data: finalTopGroups });

  } catch (error) {
    console.error('Error fetching top groups:', error);
    res.status(500).json({ success: false, message: 'Server Error' });
  }
});

module.exports = router;