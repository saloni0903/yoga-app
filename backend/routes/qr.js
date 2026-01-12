// backend/routes/qr.js
const express = require('express');
const router = express.Router();

const SessionQRCode = require('../model/SessionQRCode');
const Attendance = require('../model/Attendance');
const GroupMember = require('../model/GroupMember');
const Group = require('../model/Group');
const User = require('../model/User');

// Generate QR code for a session
router.post('/generate', async (req, res) => {
  try {
    const { group_id, session_date, created_by, options = {} } = req.body;

    const qrCode = await SessionQRCode.generateForSession(
      group_id,
      new Date(session_date),
      created_by,
      options
    );

    res.status(201).json({
      success: true,
      message: 'QR code generated successfully',
      data: qrCode
    });
  } catch (error) {
    console.error('Generate QR code error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to generate QR code',
      error: error.message
    });
  }
});

// Scan QR code and mark attendance
router.post('/scan', async (req, res) => {
  try {
    const { token, user_id, location } = req.body;

    // Validate and use QR code
    const qrCode = await SessionQRCode.validateAndUse(token, user_id, location);

    // Check if user is a member of the group
    const membership = await GroupMember.findOne({
      where: {
        user_id,
        group_id: qrCode.group_id,
        status: 'active',
      },
    });

    if (!membership) {
      return res.status(400).json({
        success: false,
        message: 'You are not a member of this group'
      });
    }

    // Check if attendance already exists for this session
    const existingAttendance = await Attendance.findOne({
      where: {
        user_id,
        group_id: qrCode.group_id,
        session_date: qrCode.session_date,
      },
    });

    if (existingAttendance) {
      return res.status(400).json({
        success: false,
        message: 'Attendance already marked for this session'
      });
    }

    // Mark attendance
    const attendance = await Attendance.create({
      user_id,
      group_id: qrCode.group_id,
      session_date: qrCode.session_date,
      qr_code_id: qrCode.id,
      attendance_type: 'present',
      location_verified: !!location,
      gps_coordinates: location
        ? {
            latitude: location.latitude,
            longitude: location.longitude,
          }
        : null,
    });

    // Update membership attendance count
    membership.attendance_count = Number(membership.attendance_count || 0) + 1;
    membership.last_attended = new Date();
    await membership.save();

    res.json({
      success: true,
      message: 'Attendance marked successfully',
      data: {
        attendance,
        qrCode: {
          session_date: qrCode.session_date,
          group_id: qrCode.group_id
        }
      }
    });
  } catch (error) {
    console.error('Scan QR code error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Failed to scan QR code'
    });
  }
});

// Get active QR codes for a group
router.get('/group/:group_id', async (req, res) => {
  try {
    const { group_id } = req.params;
    const { session_date } = req.query;

    const qrCodes = await SessionQRCode.getActiveForGroup(
      group_id,
      session_date ? new Date(session_date) : null
    );

    res.json({
      success: true,
      data: qrCodes,
    });
  } catch (error) {
    console.error('Get group QR codes error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch QR codes',
      error: error.message,
    });
  }
});

// Deactivate QR code
router.put('/:id/deactivate', async (req, res) => {
  try {
    const qrCode = await SessionQRCode.findByPk(req.params.id);
    if (!qrCode) {
      return res.status(404).json({
        success: false,
        message: 'QR code not found',
      });
    }

    await qrCode.update({ is_active: false });

    res.json({
      success: true,
      message: 'QR code deactivated successfully',
      data: qrCode,
    });
  } catch (error) {
    console.error('Deactivate QR code error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to deactivate QR code',
      error: error.message,
    });
  }
});

// Get QR code usage statistics
router.get('/:id/stats', async (req, res) => {
  try {
    const { id } = req.params;

    const qrCode = await SessionQRCode.findByPk(id);
    if (!qrCode) {
      return res.status(404).json({
        success: false,
        message: 'QR code not found',
      });
    }

    const attendance = await Attendance.findAll({
      where: { qr_code_id: id },
      include: [{ model: User, as: 'user', attributes: ['id', 'firstName', 'lastName', 'email'] }],
    });

    const stats = {
      qr_code: {
        token: qrCode.token,
        session_date: qrCode.session_date,
        created_at: qrCode.created_at,
        expires_at: qrCode.expires_at,
        is_valid: qrCode.is_valid,
      },
      usage: {
        total_scans: qrCode.usage_count,
        max_usage: qrCode.max_usage,
        remaining_usage: Number(qrCode.max_usage) - Number(qrCode.usage_count),
      },
      attendance: {
        total_marked: attendance.length,
        present: attendance.filter(a => a.attendance_type === 'present').length,
        late: attendance.filter(a => a.attendance_type === 'late').length,
        early_leave: attendance.filter(a => a.attendance_type === 'early_leave').length,
      },
    };

    res.json({
      success: true,
      data: stats,
    });
  } catch (error) {
    console.error('Get QR code stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch QR code statistics',
      error: error.message,
    });
  }
});

// Get QR code by token
router.get('/:token', async (req, res) => {
  try {
    const { token } = req.params;

    const qrCode = await SessionQRCode.findOne({
      where: { token },
      include: [
        {
          model: Group,
          as: 'group',
          attributes: ['id', 'group_name', 'location_address', 'schedule'],
        },
        {
          model: User,
          as: 'creator',
          attributes: ['id', 'firstName', 'lastName'],
        },
      ],
    });

    if (!qrCode) {
      return res.status(404).json({
        success: false,
        message: 'QR code not found'
      });
    }

    res.json({
      success: true,
      data: qrCode
    });
  } catch (error) {
    console.error('Get QR code error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch QR code',
      error: error.message
    });
  }
});

module.exports = router;
