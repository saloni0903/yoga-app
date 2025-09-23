// backend/routes/groups.js

const express = require('express');
const Group = require('../model/Group');
const GroupMember = require('../model/GroupMember');
const router = express.Router();
const auth = require('../middleware/auth');

// Get all groups
router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 10, search, instructor_id } = req.query; // Added instructor_id
    const query = {};

    if (search) {
      query.$or = [
        { group_name: { $regex: search, $options: 'i' } },
        { location_text: { $regex: search, $options: 'i' } },
      ];
    }
    
    // ✅ FIX: Data Isolation Logic
    // If an instructor_id is provided in the query, only return groups
    // created by that specific instructor.
    if (instructor_id) {
        query.instructor_id = instructor_id;
    }

    const groups = await Group.find(query)
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
    res.status(500).json({
      success: false,
      message: 'Failed to fetch groups',
      error: error.message
    });
  }
});


router.get('/my-groups', auth, async (req, res) => {
  try {
    // 1. Find all memberships for the current user
    const memberships = await GroupMember.find({ user_id: req.user.id });

    // 2. Extract just the group IDs from the memberships
    const groupIds = memberships.map(m => m.group_id);

    // 3. Find all groups that match those IDs and populate the instructor's name
    const groups = await Group.find({
      '_id': { $in: groupIds }
    }).populate('instructor_id', 'fullName'); // Fetches instructor's name

    res.json({ success: true, data: { groups } });
  } catch (error) {
    console.error('Error fetching user groups:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Get group by ID (This one can still populate for detail views)
router.get('/:id', async (req, res) => {
  try {
    const group = await Group.findById(req.params.id)
      .populate('instructor_id', 'firstName lastName email phone');
    
    if (!group) {
      return res.status(404).json({ success: false, message: 'Group not found' });
    }

    const memberCount = await GroupMember.countDocuments({ 
      group_id: req.params.id, 
      status: 'active' 
    });

    res.json({
      success: true,
      data: {
        ...group.toObject({ virtuals: true }), // Ensure virtuals are included
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

    if (!instructor_id) {
      return res.status(400).json({ success: false, message: 'instructor_id is required' });
    }
    if (!latitude || !longitude) {
      return res.status(400).json({ success: false, message: 'latitude and longitude are required' });
    }

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
    
    const group = new Group(groupData);
    await group.save();

    res.status(201).json({
      success: true,
      message: 'Group created successfully',
      data: group
    });
  } catch (error) {
    console.error('Create group error:', error);
    // Provide a more helpful error message for validation failures
    if (error.name === 'ValidationError') {
      return res.status(400).json({ success: false, message: 'Group validation failed', error: error.message });
    }
    res.status(500).json({
      success: false,
      message: 'Failed to create group',
      error: error.message
    });
  }
});

// All other routes (PUT, DELETE, /join, etc.) remain the same.
// ... (paste the rest of your original groups.js file here) ...
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
// router.post('/:id/join', async (req, res) => {
//   try {
//     const { user_id } = req.body;
    
//     // Check if user is already a member
//     const existingMember = await GroupMember.findOne({
//       user_id,
//       group_id: req.params.id
//     });

//     if (existingMember) {
//       return res.status(400).json({
//         success: false,
//         message: 'User is already a member of this group'
//       });
//     }

//     const membership = new GroupMember({
//       user_id,
//       group_id: req.params.id
//     });

//     await membership.save();

//     res.status(201).json({
//       success: true,
//       message: 'Successfully joined the group',
//       data: membership
//     });
//   } catch (error) {
//     console.error('Join group error:', error);
//     res.status(500).json({
//       success: false,
//       message: 'Failed to join group',
//       error: error.message
//     });
//   }
// });

router.post('/:id/join', auth, async (req, res) => {
  try {
    const user_id = req.user._id.toString(); // ✅ take from JWT
    const group_id = req.params.id;

    const existingMember = await GroupMember.findOne({ user_id, group_id });
    if (existingMember) {
      return res.status(400).json({
        success: false,
        message: 'User is already a member of this group'
      });
    }

    const membership = new GroupMember({ user_id, group_id });
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