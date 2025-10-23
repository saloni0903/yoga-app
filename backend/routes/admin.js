// backend/routes/admin.js
const express = require('express');
const router = express.Router();
const User = require('../model/User');
const Attendance = require('../model/Attendance');
const isAdmin = require('../middleware/isAdmin'); // Import our new middleware

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

module.exports = router;