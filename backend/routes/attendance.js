// REPLACE YOUR ENTIRE backend/routes/attendance.js FILE WITH THIS

const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Attendance = require('../model/Attendance');
const GroupMember = require('../model/GroupMember');
const SessionQRCode = require('../model/SessionQRCode');
const User = require('../model/User'); // <-- REQUIRED FOR STREAK
const Group = require('../model/Group'); // <-- REQUIRED FOR STREAK

const isAdmin = require('../middleware/isAdmin');

// --- ✨ NEW HELPER FUNCTION FOR STREAK & STATS ---
async function updateUserStats(userId, groupId, sessionDate) {
  try {
    const user = await User.findById(userId);
    const group = await Group.findById(groupId);

    if (!user || !group) {
      console.log('User or Group not found, cannot update stats.');
      return;
    }

    // 1. Update Total Sessions & Minutes
    const [startHour, startMin] = group.schedule.startTime.split(':').map(Number);
    const [endHour, endMin] = group.schedule.endTime.split(':').map(Number);
    const durationInMinutes = (endHour * 60 + endMin) - (startHour * 60 + startMin);

    user.totalSessionsAttended = (user.totalSessionsAttended || 0) + 1;
    if (durationInMinutes > 0) {
      user.totalMinutesPracticed = (user.totalMinutesPracticed || 0) + durationInMinutes;
    }

    // 2. Update Streak Logic
    const currentSessionDay = new Date(sessionDate);
    currentSessionDay.setHours(0, 0, 0, 0);

    const yesterday = new Date(currentSessionDay);
    yesterday.setDate(currentSessionDay.getDate() - 1);

    // Find the most recent attendance *before* this session's day
    const lastAttendance = await Attendance.findOne({
      user_id: userId,
      session_date: { $lt: currentSessionDay }
    }).sort({ session_date: -1 });

    if (!lastAttendance) {
      // This is the user's first-ever attendance (or first in a long time)
      user.currentStreak = 1;
    } else {
      const lastSessionDate = new Date(lastAttendance.session_date);
      lastSessionDate.setHours(0, 0, 0, 0);

      if (lastSessionDate.getTime() === yesterday.getTime()) {
        // Consecutive day!
        user.currentStreak = (user.currentStreak || 0) + 1;
      } else if (lastSessionDate.getTime() < yesterday.getTime()) {
        // Streak was broken (last attendance was > 1 day ago)
        user.currentStreak = 1;
      }
      // If lastSessionDate.getTime() === currentSessionDay.getTime(),
      // it means they already attended today, so we do nothing (streak doesn't increase twice).
      // But our $lt query prevents this case anyway.
    }

    await user.save();
    console.log(`Stats updated for user ${userId}: Streak ${user.currentStreak}`);

  } catch (error) {
    console.error(`Failed to update stats for user ${userId}:`, error.message);
  }
}
// --- ✨ END OF HELPER FUNCTION ---


// Mark attendance
router.post('/mark', async (req, res) => {
  try {
    const { user_id, group_id, session_date, qr_code_id, attendance_type = 'present' } = req.body;

    const membership = await GroupMember.findOne({
      user_id,
      group_id,
      status: 'active'
    });

    if (!membership) {
      return res.status(400).json({
        success: false,
        message: 'User is not a member of this group'
      });
    }

    const sessionDay = new Date(session_date);
    // Set to start of the day for accurate checking
    sessionDay.setHours(0, 0, 0, 0); 
    const nextDay = new Date(sessionDay);
    nextDay.setDate(sessionDay.getDate() + 1);

    const existingAttendance = await Attendance.findOne({
      user_id,
      group_id,
      session_date: {
        $gte: sessionDay,
        $lt: nextDay
      }
    });

    if (existingAttendance) {
      return res.status(400).json({
        success: false,
        message: 'Attendance already marked for this session date'
      });
    }

    const attendance = new Attendance({
      user_id,
      group_id,
      session_date: new Date(session_date), // Store exact time
      qr_code_id,
      attendance_type
    });

    await attendance.save();

    membership.attendance_count = (membership.attendance_count || 0) + 1;
    membership.last_attended = new Date(session_date);
    await membership.save();

    // --- ✨ ADDED STREAK LOGIC ---
    if (attendance_type === 'present') {
      await updateUserStats(user_id, group_id, attendance.session_date);
    }
    // ---

    res.status(201).json({
      success: true,
      message: 'Attendance marked successfully',
      data: attendance
    });
  } catch (error) {
    console.error('Mark attendance error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark attendance',
      error: error.message
    });
  }
});

// Get attendance for a specific session
router.get('/session/:group_id/:session_date', async (req, res) => {
  try {
    const { group_id, session_date } = req.params;
    
    const attendance = await Attendance.getSessionAttendance(group_id, new Date(session_date));
    
    res.json({
      success: true,
      data: attendance
    });
  } catch (error) {
    console.error('Get session attendance error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch session attendance',
      error: error.message
    });
  }
});

// Get user's attendance history
router.get('/user/:user_id', async (req, res) => {
  try {
    const { user_id } = req.params;
    const { group_id, start_date, end_date, page = 1, limit = 10 } = req.query;
    
    const query = { user_id };
    if (group_id) query.group_id = group_id;
    
    if (start_date && end_date) {
      query.session_date = {
        $gte: new Date(start_date),
        $lte: new Date(end_date)
      };
    }

    const attendance = await Attendance.find(query)
      .populate('group_id', 'group_name location_text')
      .sort({ session_date: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Attendance.countDocuments(query);

    res.json({
      success: true,
      data: {
        attendance,
        pagination: {
          current: parseInt(page),
          pages: Math.ceil(total / limit),
          total
        }
      }
    });
  } catch (error) {
    console.error('Get user attendance error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user attendance',
      error: error.message
    });
  }
});

// Get attendance statistics for a group
router.get('/stats/:group_id', async (req, res) => {
  try {
    const { group_id } = req.params;
    const { start_date, end_date } = req.query;
    
    const stats = await Attendance.getAttendanceStats(
      group_id,
      start_date ? new Date(start_date) : null,
      end_date ? new Date(end_date) : null
    );
    
    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Get attendance stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch attendance statistics',
      error: error.message
    });
  }
});

// Update attendance
router.put('/:id', async (req, res) => {
  try {
    const { attendance_type, notes, instructor_notes, rating, feedback } = req.body;
    
    const updateData = {};
    if (attendance_type) updateData.attendance_type = attendance_type;
    if (notes) updateData.notes = notes;
    if (instructor_notes) updateData.instructor_notes = instructor_notes;
    if (rating) updateData.rating = rating;
    if (feedback) updateData.feedback = feedback;

    const attendance = await Attendance.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    ).populate('user_id', 'firstName lastName email');

    if (!attendance) {
      return res.status(404).json({
        success: false,
        message: 'Attendance record not found'
      });
    }
    
    // Note: You might want to re-calculate streak here if attendance_type changes
    // from 'absent' to 'present', but that's a more complex logic.
    // For now, streak is only calculated on *new* 'present' marks.

    res.json({
      success: true,
      message: 'Attendance updated successfully',
      data: attendance
    });
  } catch (error) {
    console.error('Update attendance error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update attendance',
      error: error.message
    });
  }
});

// Delete attendance
router.delete('/:id', async (req, res) => {
  try {
    const attendance = await Attendance.findByIdAndDelete(req.params.id);
    
    if (!attendance) {
      return res.status(404).json({
        success: false,
        message: 'Attendance record not found'
      });
    }

    const membership = await GroupMember.findOne({
      user_id: attendance.user_id,
      group_id: attendance.group_id
    });

    if (membership && membership.attendance_count > 0) {
      membership.attendance_count -= 1;
      await membership.save();
    }
    
    // Note: Deleting an attendance record *should* trigger a streak re-calculation,
    // but that is complex. For now, we'll just let the next check fix it.

    res.json({
      success: true,
      message: 'Attendance record deleted successfully'
    });
  } catch (error) {
    console.error('Delete attendance error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete attendance',
      error: error.message
    });
  }
});

// Scan QR Code
router.post('/scan', auth, async (req, res) => {
  try {
    const { token } = req.body;
    const userId = req.user.id; // User ID from auth middleware

    if (!token) {
      return res.status(400).json({ success: false, message: 'QR token is required.' });
    }

    const qrCode = await SessionQRCode.findOne({ token: token });
    if (!qrCode) {
      return res.status(404).json({ success: false, message: 'Invalid or incorrect QR code.' });
    }

    if (new Date() > qrCode.expires_at) {
      return res.status(400).json({ success: false, message: 'This QR code has expired.' });
    }

    const groupId = qrCode.group_id;
    const membership = await GroupMember.findOne({ user_id: userId, group_id: groupId, status: 'active' }); // Check status
    if (!membership) {
      return res.status(403).json({ success: false, message: 'You are not an active member of this group.' });
    }

    // Check if attendance already marked for this *specific session date*
    const sessionDay = new Date(qrCode.session_date);
    sessionDay.setHours(0, 0, 0, 0);
    const nextDay = new Date(sessionDay);
    nextDay.setDate(sessionDay.getDate() + 1);

    const existingAttendance = await Attendance.findOne({
      user_id: userId,
      group_id: groupId,
      session_date: {
        $gte: sessionDay,
        $lt: nextDay
      }
    });

    if (existingAttendance) {
      return res.status(400).json({ success: false, message: 'Attendance already marked for this session date.' });
    }

    const attendance = new Attendance({
      user_id: userId,
      group_id: groupId,
      session_date: qrCode.session_date, // Use the exact date from QR code
      qr_code_id: qrCode._id,
      attendance_type: 'present' // Scanning always marks 'present'
    });
    await attendance.save();

    // Update membership stats
    membership.attendance_count = (membership.attendance_count || 0) + 1;
    membership.last_attended = qrCode.session_date;
    await membership.save();

    // --- ✨ ADDED STREAK LOGIC ---
    await updateUserStats(userId, groupId, attendance.session_date);
    // ---

    res.status(201).json({ success: true, message: 'Attendance marked successfully!', data: attendance });

  } catch (error) {
    console.error('Error scanning QR code:', error);
    res.status(500).json({ success: false, message: 'Server error during scan.' });
  }
});


// GET All Attendance Records (For Admin)
router.get('/', auth, isAdmin, async (req, res) => {
  try {
    const { 
        page = 1, 
        limit = 20,
        sort = '-marked_at', 
        populate = ''
    } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    let query = Attendance.find();

    if (sort) {
        const sortQuery = sort.split(',').join(' '); 
        query = query.sort(sortQuery);
    }

    const fieldsToPopulate = populate.split(',').filter(field => field);
    if (fieldsToPopulate.includes('group_id')) {
        query = query.populate({ 
            path: 'group_id', 
            select: 'group_name color instructor_id'
        });
    }
    if (fieldsToPopulate.includes('user_id')) {
        query = query.populate({
            path: 'user_id',
            select: 'firstName lastName email'
        });
    }
    if (fieldsToPopulate.includes('instructor_id')) {
        query = query.populate({ 
            path: 'group_id', 
            populate: { path: 'instructor_id', select: 'firstName lastName' } 
        });
    }

    query = query.skip(skip).limit(parseInt(limit));

    const attendanceRecords = await query.lean();
    const total = await Attendance.countDocuments();

    res.json({
      success: true,
      data: attendanceRecords,
      pagination: {
        current: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit),
        total,
      },
    });

  } catch (error) {
    console.error('Get all attendance error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch attendance records', error: error.message });
  }
});

module.exports = router;