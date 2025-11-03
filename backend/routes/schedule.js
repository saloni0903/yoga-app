// REPLACE YOUR ENTIRE backend/routes/schedule.js FILE WITH THIS

const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Group = require('../model/Group');
const GroupMember = require('../model/GroupMember');
const mongoose = require('mongoose');

// --- HELPER FUNCTION: Calculates sessions for a list of groups ---
// (startDate aur endDate UTC mein 'YYYY-MM-DD' format mein hone chahiye)
function calculateSessionsForGroups(groups, startDate, endDate) {
  const sessions = [];
  const dayMap = { 'Sunday': 0, 'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4, 'Friday': 5, 'Saturday': 6 };
  
  const start = new Date(startDate);
  const end = new Date(endDate);

  for (const group of groups) {
    const schedule = group.schedule;
    if (!schedule || !schedule.days || schedule.days.length === 0) {
      continue; // Skip group if no schedule
    }

    // Convert group's schedule days to numbers (0-6)
    const scheduledDays = new Set(schedule.days.map(day => dayMap[day]));
    const [startHour, startMinute] = schedule.startTime.split(':').map(Number);
    const [endHour, endMinute] = schedule.endTime.split(':').map(Number);

    // Loop from startDate to endDate
    let currentDate = new Date(start);
    while (currentDate <= end) {
      
      // Check if this day is in the group's schedule
      if (scheduledDays.has(currentDate.getUTCDay())) {
        
        // Create start time in UTC
        const sessionStartTime = new Date(currentDate);
        sessionStartTime.setUTCHours(startHour, startMinute, 0, 0);

        // Create end time in UTC
        const sessionEndTime = new Date(currentDate);
        sessionEndTime.setUTCHours(endHour, endMinute, 0, 0);

        // Add this session to our list
        sessions.push({
          _id: new mongoose.Types.ObjectId().toString(), // transient ID
          sessionDate: sessionStartTime.toISOString(),
          endTime: sessionEndTime.toISOString(),
          groupName: group.group_name,
          groupId: group._id.toString(),
          color: group.color,
          groupType: group.groupType,
          meetLink: group.meetLink,
        });
      }
      // Move to the next day
      currentDate.setUTCDate(currentDate.getUTCDate() + 1);
    }
  }
  return sessions;
}


// @route   GET api/schedule/participant
// @desc    Get all upcoming sessions for the logged-in PARTICIPANT
// @access  Private
router.get('/participant', auth, async (req, res) => {
  try {
    // 1. Find all groups the user is a member of
    const memberships = await GroupMember.find({ user_id: req.user.id, status: 'active' }).select('group_id');
    const groupIds = memberships.map(m => m.group_id);

    // 2. Find details of all those groups
    const groups = await Group.find({ 
      '_id': { $in: groupIds },
      'schedule.endDate': { $gte: new Date() } // Only groups that haven't ended
    }).lean();

    // 3. Define date range (from today to 2 months from now)
    const startDate = new Date();
    startDate.setUTCHours(0, 0, 0, 0);
    const endDate = new Date(startDate);
    endDate.setMonth(endDate.getMonth() + 2); // 2 months in future

    // 4. Calculate sessions
    const sessions = calculateSessionsForGroups(groups, startDate.toISOString().split('T')[0], endDate.toISOString().split('T')[0]);

    // 5. Sort by date
    sessions.sort((a, b) => new Date(a.sessionDate) - new Date(b.sessionDate));

    res.json({ success: true, data: sessions });
  } catch (error) {
    console.error('Error fetching participant schedule:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});


// @route   GET api/schedule/instructor
// @desc    Get all upcoming sessions for the logged-in INSTRUCTOR
// @access  Private (auth middleware already checks for login)
router.get('/instructor', auth, async (req, res) => {
  try {
    // 1. Find all groups created by this instructor
    const groups = await Group.find({ 
      'instructor_id': req.user.id,
      'schedule.endDate': { $gte: new Date() } // Only groups that haven't ended
    }).lean();

    // 2. Define date range (from today to 2 months from now)
    const startDate = new Date();
    startDate.setUTCHours(0, 0, 0, 0);
    const endDate = new Date(startDate);
    endDate.setMonth(endDate.getMonth() + 2);

    // 3. Calculate sessions
    const sessions = calculateSessionsForGroups(groups, startDate.toISOString().split('T')[0], endDate.toISOString().split('T')[0]);

    // 4. Sort by date
    sessions.sort((a, b) => new Date(a.sessionDate) - new Date(b.sessionDate));

    res.json({ success: true, data: sessions });
  } catch (error) {
    console.error('Error fetching instructor schedule:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;