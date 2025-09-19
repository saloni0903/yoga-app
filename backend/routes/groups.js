const express = require('express');
const Group = require('../model/Group');
const GroupMember = require('../model/GroupMember');
const router = express.Router();

// Get all groups
router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 10, search, yoga_style, difficulty_level, is_active, location } = req.query;
    const query = {};

    if (search) {
      query.$or = [
        { group_name: { $regex: search, $options: 'i' } },
        { location_text: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }

    if (location) {
      query.location = { $regex: location, $options: 'i' };
    }

    if (yoga_style) {
      query.yoga_style = yoga_style;
    }

    if (difficulty_level) {
      query.difficulty_level = difficulty_level;
    }

    if (is_active !== undefined) {
      query.is_active = is_active === 'true';
    }

    const groups = await Group.find(query)
      .populate('instructor_id', 'firstName lastName email')
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ created_at: -1 });

    const total = await Group.countDocuments(query);

    res.json({
      success: true,
      data: {
        groups,
        pagination: {
          current: parseInt(page),
          pages: Math.ceil(total / limit),
          total
        }
      }
    });
  } catch (error) {
    console.error('Get groups error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch groups',
      error: error.message
    });
  }
});

// Get groups by location
router.get('/location/:location', async (req, res) => {
  try {
    const { location } = req.params;
    const { page = 1, limit = 10, yoga_style, difficulty_level, is_active } = req.query;
    const query = {
      location: { $regex: location, $options: 'i' }
    };

    if (yoga_style) {
      query.yoga_style = yoga_style;
    }

    if (difficulty_level) {
      query.difficulty_level = difficulty_level;
    }

    if (is_active !== undefined) {
      query.is_active = is_active === 'true';
    }

    const groups = await Group.find(query)
      .populate('instructor_id', 'firstName lastName email')
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ created_at: -1 });

    const total = await Group.countDocuments(query);

    res.json({
      success: true,
      data: {
        groups,
        location,
        pagination: {
          current: parseInt(page),
          pages: Math.ceil(total / limit),
          total
        }
      }
    });
  } catch (error) {
    console.error('Get groups by location error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch groups by location',
      error: error.message
    });
  }
});

// Get group by ID
router.get('/:id', async (req, res) => {
  try {
    const group = await Group.findById(req.params.id)
      .populate('instructor_id', 'firstName lastName email phone');
    
    if (!group) {
      return res.status(404).json({
        success: false,
        message: 'Group not found'
      });
    }

    // Get group members count
    const memberCount = await GroupMember.countDocuments({ 
      group_id: req.params.id, 
      status: 'active' 
    });

    res.json({
      success: true,
      data: {
        ...group.toObject(),
        memberCount
      }
    });
  } catch (error) {
    console.error('Get group error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch group',
      error: error.message
    });
  }
});

// Create new group
router.post('/', async (req, res) => {
  try {
    const {
      group_name,
      location,
      location_text,
      latitude,
      longitude,
      timings_text,
      description,
      yoga_style,
      difficulty_level,
      session_duration,
      price_per_session,
      max_participants,
      instructor_id
    } = req.body;

    // Validate required fields
    if (!instructor_id) {
      return res.status(400).json({
        success: false,
        message: 'instructor_id is required'
      });
    }

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'latitude and longitude are required'
      });
    }

    // Convert string numbers to actual numbers
    const groupData = {
      instructor_id,
      group_name,
      location,
      location_text,
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      timings_text,
      description,
      yoga_style,
      difficulty_level,
      session_duration: parseInt(session_duration) || 60,
      price_per_session: parseFloat(price_per_session) || 0,
      max_participants: parseInt(max_participants) || 20
    };

    // Validate that latitude and longitude are valid numbers
    if (isNaN(groupData.latitude) || isNaN(groupData.longitude)) {
      return res.status(400).json({
        success: false,
        message: 'latitude and longitude must be valid numbers'
      });
    }

    const group = new Group(groupData);
    await group.save();

    const populatedGroup = await Group.findById(group._id)
      .populate('instructor_id', 'firstName lastName email');

    res.status(201).json({
      success: true,
      message: 'Group created successfully',
      data: populatedGroup
    });
  } catch (error) {
    console.error('Create group error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create group',
      error: error.message
    });
  }
});

// Update group
router.put('/:id', async (req, res) => {
  try {
    const group = await Group.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    ).populate('instructor_id', 'firstName lastName email');

    if (!group) {
      return res.status(404).json({
        success: false,
        message: 'Group not found'
      });
    }

    res.json({
      success: true,
      message: 'Group updated successfully',
      data: group
    });
  } catch (error) {
    console.error('Update group error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update group',
      error: error.message
    });
  }
});

// Delete group
router.delete('/:id', async (req, res) => {
  try {
    const group = await Group.findByIdAndDelete(req.params.id);
    
    if (!group) {
      return res.status(404).json({
        success: false,
        message: 'Group not found'
      });
    }

    // Also remove all group members
    await GroupMember.deleteMany({ group_id: req.params.id });

    res.json({
      success: true,
      message: 'Group deleted successfully'
    });
  } catch (error) {
    console.error('Delete group error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete group',
      error: error.message
    });
  }
});

// Get group members
router.get('/:id/members', async (req, res) => {
  try {
    const members = await GroupMember.getActiveMembers(req.params.id);
    
    res.json({
      success: true,
      data: members
    });
  } catch (error) {
    console.error('Get group members error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch group members',
      error: error.message
    });
  }
});

// Join group
router.post('/:id/join', async (req, res) => {
  try {
    const { user_id } = req.body;
    
    // Check if user is already a member
    const existingMember = await GroupMember.findOne({
      user_id,
      group_id: req.params.id
    });

    if (existingMember) {
      return res.status(400).json({
        success: false,
        message: 'User is already a member of this group'
      });
    }

    const membership = new GroupMember({
      user_id,
      group_id: req.params.id
    });

    await membership.save();

    res.status(201).json({
      success: true,
      message: 'Successfully joined the group',
      data: membership
    });
  } catch (error) {
    console.error('Join group error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to join group',
      error: error.message
    });
  }
});

// Leave group
router.delete('/:id/leave', async (req, res) => {
  try {
    const { user_id } = req.body;
    
    const membership = await GroupMember.findOneAndUpdate(
      { user_id, group_id: req.params.id },
      { status: 'left' },
      { new: true }
    );

    if (!membership) {
      return res.status(404).json({
        success: false,
        message: 'Membership not found'
      });
    }

    res.json({
      success: true,
      message: 'Successfully left the group'
    });
  } catch (error) {
    console.error('Leave group error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to leave group',
      error: error.message
    });
  }
});

module.exports = router;