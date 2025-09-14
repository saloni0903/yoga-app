const express = require('express');
const Attendance = require('../model/Attendance');
const GroupMember = require('../model/GroupMember');
const router = express.Router();

// Mark attendance
router.post('/mark', async (req, res) => {
  try {
    const { user_id, group_id, session_date, qr_code_id, attendance_type = 'present' } = req.body;

    // Check if user is a member of the group
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

    // Check if attendance already exists for this session
    const existingAttendance = await Attendance.findOne({
      user_id,
      group_id,
      session_date: new Date(session_date)
    });

    if (existingAttendance) {
      return res.status(400).json({
        success: false,
        message: 'Attendance already marked for this session'
      });
    }

    const attendance = new Attendance({
      user_id,
      group_id,
      session_date: new Date(session_date),
      qr_code_id,
      attendance_type
    });

    await attendance.save();

    // Update membership attendance count
    membership.attendance_count += 1;
    membership.last_attended = new Date();
    await membership.save();

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

    // Update membership attendance count
    const membership = await GroupMember.findOne({
      user_id: attendance.user_id,
      group_id: attendance.group_id
    });

    if (membership && membership.attendance_count > 0) {
      membership.attendance_count -= 1;
      await membership.save();
    }

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

module.exports = router;
