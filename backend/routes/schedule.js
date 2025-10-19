// backend/routes/schedule.js
const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Group = require('../model/Group');
const mongoose = require('mongoose');

// GET dynamically generated sessions for a group within a date range
router.get('/sessions', auth, async (req, res) => {
    try {
        const { groupId, startDate, endDate } = req.query;

        if (!groupId || !startDate || !endDate) {
            return res.status(400).json({ success: false, message: 'groupId, startDate, and endDate are required query parameters.' });
        }

        const group = await Group.findById(groupId).lean(); // .lean() for performance

        if (!group) {
            return res.status(404).json({ success: false, message: 'Group not found' });
        }

        // --- DYNAMIC SESSION CALCULATION LOGIC ---
        const sessions = [];
        const schedule = group.schedule;
        
        if (!schedule || !schedule.days || schedule.days.length === 0) {
            return res.json({ success: true, data: [] }); // No schedule, no sessions
        }

        const dayMap = { 'Sunday': 0, 'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4, 'Friday': 5, 'Saturday': 6 };
        const scheduledDays = new Set(schedule.days.map(day => dayMap[day]));
        
        let currentDate = new Date(startDate);
        const finalDate = new Date(endDate);
        const [startHour, startMinute] = schedule.startTime.split(':').map(Number);

        while (currentDate <= finalDate) {
            // Check if the current day of the week is in our schedule
            if (scheduledDays.has(currentDate.getUTCDay())) {
                const sessionDate = new Date(currentDate);
                sessionDate.setUTCHours(startHour, startMinute, 0, 0);

                // This is a dynamically generated session object. It does not exist in the DB.
                sessions.push({
                    _id: new mongoose.Types.ObjectId().toString(), // A transient ID for frontend keying
                    group_id: { // Simulate population for frontend compatibility
                        _id: group._id,
                        group_name: group.group_name,
                        color: group.color,
                    },
                    session_date: sessionDate.toISOString(),
                    status: 'upcoming', // This can be enhanced later with attendance data
                });
            }
            // Move to the next day
            currentDate.setUTCDate(currentDate.getUTCDate() + 1);
        }

        res.json({ success: true, data: sessions });

    } catch (error) {
        console.error('Error fetching dynamic schedule:', error);
        res.status(500).json({ success: false, message: 'Server error while calculating schedule.' });
    }
});

module.exports = router;