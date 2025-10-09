const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Session = require('../model/Session');
const GroupMember = require('../model/GroupMember');
const Attendance = require('../model/Attendance');
const Group = require('../model/Group');
const mongoose = require('mongoose');

// GET schedule for the logged-in INSTRUCTOR
router.get('/instructor', auth, async (req, res) => {
    try {
        const instructorId = req.user.id;
        
        // Find all sessions created by this instructor
        const sessions = await Session.find({ instructor_id: instructorId })
            .populate({
                path: 'group_id',
                select: 'group_name color' // Populate group name and color
            })
            .sort({ session_date: 1 }); // Sort by date

        res.json({ success: true, data: sessions });

    } catch (error) {
        console.error('Error fetching instructor schedule:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// GET schedule for the logged-in PARTICIPANT
router.get('/participant', auth, async (req, res) => {
    try {
        const participantId = req.user.id;

        // 1. Find all groups the participant is a member of
        const memberships = await GroupMember.find({ user_id: participantId, status: 'active' });
        const groupIds = memberships.map(m => m.group_id);

        // 2. Find all sessions for those groups
        const sessions = await Session.find({ group_id: { $in: groupIds } })
            .populate({
                path: 'group_id',
                select: 'group_name color'
            })
            .sort({ session_date: 1 })
            .lean(); // Use .lean() for plain JS objects to modify them

        // 3. Find all attendance records for this user
        const attendanceRecords = await Attendance.find({ user_id: participantId });
        const attendedSessionIds = new Set(attendanceRecords.map(a => a.session_id));

        // 4. Determine the status for each session (upcoming, attended, missed)
        const now = new Date();
        const schedule = sessions.map(session => {
            let status = 'upcoming';
            if (session.session_date < now) {
                // It's a past session, check if attended
                status = attendedSessionIds.has(session._id) ? 'attended' : 'missed';
            }
            return {
                ...session,
                status: status, // Override the default 'upcoming' with our calculated status
            };
        });

        res.json({ success: true, data: schedule });

    } catch (error) {
        console.error('Error fetching participant schedule:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

module.exports = router;