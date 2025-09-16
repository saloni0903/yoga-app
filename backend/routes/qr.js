// In file: backend/routes/qr.js
const express = require('express');
const SessionQRCode = require('../model/SessionQRCode');
const Attendance = require('../model/Attendance');
const GroupMember = require('../model/GroupMember');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware'); // 1. Import the security middleware

// ==========================================================
// THE DEFINITIVE FIX FOR GENERATING A QR CODE
// ==========================================================
router.post('/generate', protect, async (req, res) => { // 2. Add 'protect' to the route
  try {
    const { group_id, session_date, options = {} } = req.body;
    
    // 3. Get the instructor's ID SECURELY from their token
    const created_by = req.user.id;

    // The static method in your model is great, let's use it
    const qrCode = await SessionQRCode.generateForSession(
      group_id,
      new Date(session_date),
      created_by, // Pass the secure user ID
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

// --- All other routes from your file remain the same ---
// It's good practice to protect them as well.

// Scan QR code and mark attendance
router.post('/scan', protect, async (req, res) => {
  try {
    const { token, location } = req.body;
    const user_id = req.user.id; // Securely get user ID

    // Validate and use QR code
    const qrCode = await SessionQRCode.validateAndUse(token, user_id, location);

    // Check if user is a member of the group
    const membership = await GroupMember.findOne({
      user_id,
      group_id: qrCode.group_id,
      status: 'active'
    });

    if (!membership) {
      return res.status(403).json({ // 403 Forbidden is more appropriate
        success: false,
        message: 'You are not a member of this group'
      });
    }

    // Check if attendance already exists for this session
    const existingAttendance = await Attendance.findOne({
      user_id,
      group_id: qrCode.group_id,
      session_date: qrCode.session_date
    });

    if (existingAttendance) {
      return res.status(409).json({ // 409 Conflict is more appropriate
        success: false,
        message: 'Attendance already marked for this session'
      });
    }

    // Mark attendance
    const attendance = new Attendance({
      user_id,
      group_id: qrCode.group_id,
      session_date: qrCode.session_date,
      qr_code_id: qrCode._id,
      attendance_type: 'present',
      location_verified: !!location,
      gps_coordinates: location ? {
        latitude: location.latitude,
        longitude: location.longitude
      } : undefined
    });
    await attendance.save();

    // Update membership attendance count
    membership.attendance_count = (membership.attendance_count || 0) + 1;
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
    res.status(400).json({
      success: false,
      message: error.message || 'Failed to scan QR code'
    });
  }
});

// Get QR code by token
router.get('/:token', protect, async (req, res) => {
  try {
    const { token } = req.params;
    const qrCode = await SessionQRCode.findOne({ token })
      .populate('group_id', 'group_name location_text timings_text')
      .populate('created_by', 'firstName lastName');

    if (!qrCode) {
      return res.status(404).json({ success: false, message: 'QR code not found' });
    }
    res.json({ success: true, data: qrCode });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch QR code', error: error.message });
  }
});

// Get active QR codes for a group
router.get('/group/:group_id', protect, async (req, res) => {
  try {
    const { group_id } = req.params;
    const { session_date } = req.query;
    const qrCodes = await SessionQRCode.getActiveForGroup(
      group_id,
      session_date ? new Date(session_date) : null
    );
    res.json({ success: true, data: qrCodes });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch QR codes', error: error.message });
  }
});

// Deactivate QR code
router.put('/:id/deactivate', protect, async (req, res) => {
  try {
    const qrCode = await SessionQRCode.findByIdAndUpdate(
      req.params.id,
      { is_active: false },
      { new: true }
    );
    if (!qrCode) {
      return res.status(404).json({ success: false, message: 'QR code not found' });
    }
    res.json({ success: true, message: 'QR code deactivated successfully', data: qrCode });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to deactivate QR code', error: error.message });
  }
});

// Get QR code usage statistics
router.get('/:id/stats', protect, async (req, res) => {
  try {
    const { id } = req.params;
    const qrCode = await SessionQRCode.findById(id);
    if (!qrCode) {
      return res.status(404).json({ success: false, message: 'QR code not found' });
    }
    const attendance = await Attendance.find({ qr_code_id: id })
      .populate('user_id', 'firstName lastName email');
    const stats = {
      qr_code: {
        token: qrCode.token,
        session_date: qrCode.session_date,
        expires_at: qrCode.expires_at,
        is_valid: qrCode.is_valid
      },
      usage: {
        total_scans: qrCode.usage_count,
        max_usage: qrCode.max_usage,
      },
      attendance: {
        total_marked: attendance.length,
      }
    };
    res.json({ success: true, data: stats });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch QR code statistics', error: error.message });
  }
});

module.exports = router;