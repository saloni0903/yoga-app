const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const isAdmin = require('../middleware/isAdmin');
const { Op } = require('sequelize');

const Attendance = require('../model/Attendance');
const GroupMember = require('../model/GroupMember');
const SessionQRCode = require('../model/SessionQRCode');
const User = require('../model/User');
const Group = require('../model/Group');

function toDateOnly(value) {
  return new Date(value).toISOString().split('T')[0];
}

async function updateUserStats(userId, groupId, sessionDateOnly) {
  try {
    const user = await User.findByPk(userId);
    const group = await Group.findByPk(groupId);

    if (!user || !group) {
      return;
    }

    const schedule = group.schedule || {};
    if (!schedule.startTime || !schedule.endTime) {
      return;
    }

    const [startHour, startMin] = schedule.startTime.split(':').map(Number);
    const [endHour, endMin] = schedule.endTime.split(':').map(Number);
    const durationInMinutes = endHour * 60 + endMin - (startHour * 60 + startMin);

    user.totalSessionsAttended = Number(user.totalSessionsAttended || 0) + 1;
    if (durationInMinutes > 0) {
      user.totalMinutesPracticed = Number(user.totalMinutesPracticed || 0) + durationInMinutes;
    }

    const currentSessionDay = new Date(sessionDateOnly);
    currentSessionDay.setHours(0, 0, 0, 0);

    const yesterday = new Date(currentSessionDay);
    yesterday.setDate(currentSessionDay.getDate() - 1);

    const lastAttendance = await Attendance.findOne({
      where: {
        user_id: userId,
        session_date: { [Op.lt]: sessionDateOnly },
      },
      order: [['session_date', 'DESC']],
    });

    if (!lastAttendance) {
      user.currentStreak = 1;
    } else {
      const lastSessionDate = new Date(lastAttendance.session_date);
      lastSessionDate.setHours(0, 0, 0, 0);

      if (lastSessionDate.getTime() === yesterday.getTime()) {
        user.currentStreak = Number(user.currentStreak || 0) + 1;
      } else if (lastSessionDate.getTime() < yesterday.getTime()) {
        user.currentStreak = 1;
      }
    }

    await user.save();
  } catch (error) {
    console.error(`Failed to update stats for user ${userId}:`, error.message);
  }
}

router.post('/mark', async (req, res) => {
  try {
    const { user_id, group_id, session_date, qr_code_id, attendance_type = 'present' } = req.body;

    const membership = await GroupMember.findOne({
      where: { user_id, group_id, status: 'active' },
    });

    if (!membership) {
      return res.status(400).json({ success: false, message: 'User is not a member of this group' });
    }

    const sessionDateOnly = toDateOnly(session_date);
    const existingAttendance = await Attendance.findOne({
      where: { user_id, group_id, session_date: sessionDateOnly },
    });

    if (existingAttendance) {
      return res.status(400).json({ success: false, message: 'Attendance already marked for this session date' });
    }

    const attendance = await Attendance.create({
      user_id,
      group_id,
      session_date: sessionDateOnly,
      qr_code_id: qr_code_id || null,
      attendance_type,
    });

    membership.attendance_count = Number(membership.attendance_count || 0) + 1;
    membership.last_attended = new Date(session_date);
    await membership.save();

    if (attendance_type === 'present') {
      await updateUserStats(user_id, group_id, sessionDateOnly);
    }

    res.status(201).json({ success: true, message: 'Attendance marked successfully', data: attendance });
  } catch (error) {
    console.error('Mark attendance error:', error);
    res.status(500).json({ success: false, message: 'Failed to mark attendance', error: error.message });
  }
});

router.get('/session/:group_id/:session_date', async (req, res) => {
  try {
    const { group_id, session_date } = req.params;
    const attendance = await Attendance.getSessionAttendance(group_id, toDateOnly(session_date));
    res.json({ success: true, data: attendance });
  } catch (error) {
    console.error('Get session attendance error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch session attendance', error: error.message });
  }
});

router.get('/user/:user_id', async (req, res) => {
  try {
    const { user_id } = req.params;
    const { group_id, start_date, end_date, page = 1, limit = 10 } = req.query;

    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const offset = (pageNum - 1) * limitNum;

    const where = { user_id };
    if (group_id) where.group_id = group_id;
    if (start_date && end_date) {
      where.session_date = { [Op.between]: [toDateOnly(start_date), toDateOnly(end_date)] };
    }

    const { rows: attendance, count: total } = await Attendance.findAndCountAll({
      where,
      include: [
        {
          model: Group,
          as: 'group',
          attributes: ['id', 'group_name', 'location_address', 'groupType'],
        },
      ],
      order: [['session_date', 'DESC']],
      limit: limitNum,
      offset,
    });

    res.json({
      success: true,
      data: {
        attendance,
        pagination: {
          current: pageNum,
          pages: Math.ceil(total / limitNum),
          total,
        },
      },
    });
  } catch (error) {
    console.error('Get user attendance error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch user attendance', error: error.message });
  }
});

router.get('/stats/:group_id', async (req, res) => {
  try {
    const { group_id } = req.params;
    const { start_date, end_date } = req.query;

    const stats = await Attendance.getAttendanceStats(
      group_id,
      start_date ? toDateOnly(start_date) : null,
      end_date ? toDateOnly(end_date) : null
    );

    res.json({ success: true, data: stats });
  } catch (error) {
    console.error('Get attendance stats error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch attendance statistics', error: error.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { attendance_type, notes, instructor_notes, rating, feedback } = req.body;
    const updateData = {};
    if (attendance_type !== undefined) updateData.attendance_type = attendance_type;
    if (notes !== undefined) updateData.notes = notes;
    if (instructor_notes !== undefined) updateData.instructor_notes = instructor_notes;
    if (rating !== undefined) updateData.rating = rating;
    if (feedback !== undefined) updateData.feedback = feedback;

    const attendance = await Attendance.findByPk(req.params.id);
    if (!attendance) {
      return res.status(404).json({ success: false, message: 'Attendance record not found' });
    }

    await attendance.update(updateData);

    const populated = await Attendance.findByPk(req.params.id, {
      include: [{ model: User, as: 'user', attributes: ['id', 'firstName', 'lastName', 'email'] }],
    });

    res.json({ success: true, message: 'Attendance updated successfully', data: populated });
  } catch (error) {
    console.error('Update attendance error:', error);
    res.status(500).json({ success: false, message: 'Failed to update attendance', error: error.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const attendance = await Attendance.findByPk(req.params.id);
    if (!attendance) {
      return res.status(404).json({ success: false, message: 'Attendance record not found' });
    }

    const { user_id, group_id } = attendance;
    await attendance.destroy();

    const membership = await GroupMember.findOne({ where: { user_id, group_id } });
    if (membership && Number(membership.attendance_count) > 0) {
      membership.attendance_count = Number(membership.attendance_count) - 1;
      await membership.save();
    }

    res.json({ success: true, message: 'Attendance record deleted successfully' });
  } catch (error) {
    console.error('Delete attendance error:', error);
    res.status(500).json({ success: false, message: 'Failed to delete attendance', error: error.message });
  }
});

router.post('/scan', auth, async (req, res) => {
  try {
    const { token } = req.body;
    const userId = req.user.id;

    if (!token) {
      return res.status(400).json({ success: false, message: 'QR token is required.' });
    }

    const qrCode = await SessionQRCode.findOne({ where: { token } });
    if (!qrCode) {
      return res.status(404).json({ success: false, message: 'Invalid or incorrect QR code.' });
    }
    if (new Date() > new Date(qrCode.expires_at)) {
      return res.status(400).json({ success: false, message: 'This QR code has expired.' });
    }

    const groupId = qrCode.group_id;
    const membership = await GroupMember.findOne({ where: { user_id: userId, group_id: groupId, status: 'active' } });
    if (!membership) {
      return res.status(403).json({ success: false, message: 'You are not an active member of this group.' });
    }

    const sessionDateOnly = qrCode.session_date;
    const existingAttendance = await Attendance.findOne({
      where: { user_id: userId, group_id: groupId, session_date: sessionDateOnly },
    });
    if (existingAttendance) {
      return res.status(400).json({ success: false, message: 'Attendance already marked for this session date.' });
    }

    const attendance = await Attendance.create({
      user_id: userId,
      group_id: groupId,
      session_date: sessionDateOnly,
      qr_code_id: qrCode.id,
      attendance_type: 'present',
    });

    membership.attendance_count = Number(membership.attendance_count || 0) + 1;
    membership.last_attended = new Date();
    await membership.save();

    await updateUserStats(userId, groupId, sessionDateOnly);

    res.status(201).json({ success: true, message: 'Attendance marked successfully!', data: attendance });
  } catch (error) {
    console.error('Error scanning QR code:', error);
    res.status(500).json({ success: false, message: 'Server error during scan.' });
  }
});

router.get('/', auth, isAdmin, async (req, res) => {
  try {
    const { page = 1, limit = 20, sort = '-marked_at', populate = '' } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const offset = (pageNum - 1) * limitNum;

    const order = [];
    if (sort) {
      const fields = String(sort)
        .split(',')
        .map(s => s.trim())
        .filter(Boolean);

      for (const field of fields) {
        const direction = field.startsWith('-') ? 'DESC' : 'ASC';
        const name = field.replace(/^-/, '');
        order.push([name, direction]);
      }
    }
    if (order.length === 0) {
      order.push(['marked_at', 'DESC']);
    }

    const includes = [];
    const fieldsToPopulate = String(populate)
      .split(',')
      .map(s => s.trim())
      .filter(Boolean);

    if (fieldsToPopulate.includes('group_id') || fieldsToPopulate.includes('instructor_id')) {
      const groupInclude = {
        model: Group,
        as: 'group',
        attributes: ['id', 'group_name', 'color', 'instructor_id'],
        include: [],
      };
      if (fieldsToPopulate.includes('instructor_id')) {
        groupInclude.include.push({
          model: User,
          as: 'instructor',
          attributes: ['id', 'firstName', 'lastName'],
        });
      }
      includes.push(groupInclude);
    }

    if (fieldsToPopulate.includes('user_id')) {
      includes.push({
        model: User,
        as: 'user',
        attributes: ['id', 'firstName', 'lastName', 'email'],
      });
    }

    const { rows: attendanceRecords, count: total } = await Attendance.findAndCountAll({
      include: includes,
      order,
      limit: limitNum,
      offset,
    });

    res.json({
      success: true,
      data: attendanceRecords,
      pagination: {
        current: pageNum,
        limit: limitNum,
        pages: Math.ceil(total / limitNum),
        total,
      },
    });
  } catch (error) {
    console.error('Get all attendance error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch attendance records', error: error.message });
  }
});

module.exports = router;