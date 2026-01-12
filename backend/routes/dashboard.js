// backend/routes/dashboard.js
const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const User = require('../model/User');
const Attendance = require('../model/Attendance');

// @route   GET api/dashboard
// @desc    Get user dashboard data (stats and recent attendance)
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    // 1. Fetch the current user's stats
    const user = await User.findByPk(req.user.id, {
      attributes: ['id', 'firstName', 'currentStreak', 'totalMinutesPracticed', 'totalSessionsAttended'],
    });

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // 2. Fetch the user's last 7 attendance records
    const recentAttendance = await Attendance.findAll({
      where: { user_id: req.user.id },
      order: [['session_date', 'DESC']],
      limit: 7,
      attributes: ['id', 'session_date', 'attendance_type', 'session_duration'],
    });

    res.json({
      success: true,
      data: {
        stats: user,
        recentAttendance: recentAttendance,
      },
    });
  } catch (error) {
    console.error('Get dashboard error:', error);
    res.status(500).json({ success: false, message: 'Server Error' });
  }
});

module.exports = router;