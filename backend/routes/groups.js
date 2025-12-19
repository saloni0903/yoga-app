// backend/routes/groups.js

const express = require('express');
const Group = require('../model/Group');
const GroupMember = require('../model/GroupMember');
const router = express.Router();
const auth = require('../middleware/auth');
const axios = require('axios');
const mongoose = require('mongoose');

// const Session = require('../model/Session');
const crypto = require('crypto');

// for notifications
const notificationService = require('../services/notificationService');
const { sendNotificationToUser } = require('../services/notificationService');

// Get all groups (RE-ARCHITECTED FOR ONLINE/OFFLINE)
router.get('/', async (req, res) => {
  try {
    const {
      search,
      latitude,
      longitude,
      page = 1,
      limit = 10,
      instructor_id,
    } = req.query;

    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    let query = {};

    // Filter by instructor if provided
    if (instructor_id) {
      query.instructor_id = new mongoose.Types.ObjectId(instructor_id);
    }

    // Text search across multiple fields
    if (search) {
      query.$or = [
        { group_name: { $regex: search, $options: 'i' } },
        { 'location.address': { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
        { yoga_style: { $regex: search, $options: 'i' } },
      ];
    }

    // Separate offline and online groups
    const offlineQuery = { ...query, groupType: 'offline' };
    const onlineQuery = { ...query, groupType: 'online' };

    let offlineGroups = [];
    let onlineGroups = [];

    // Fetch offline groups with distance if lat/long provided
    if (latitude && longitude) {
      const userCoords = [parseFloat(longitude), parseFloat(latitude)];
      
      offlineGroups = await Group.aggregate([
        {
          $geoNear: {
            near: { type: 'Point', coordinates: userCoords },
            distanceField: 'distance',
            spherical: true,
            maxDistance: 50000, // 50km radius
            query: offlineQuery,
          }
        },
        {
          $lookup: {
            from: 'users',
            localField: 'instructor_id',
            foreignField: '_id',
            as: 'instructor',
          }
        },
        { $unwind: { path: '$instructor', preserveNullAndEmptyArrays: true } },
        {
          $addFields: {
            instructor_id: {
              _id: '$instructor._id',
              firstName: '$instructor.firstName',
              lastName: '$instructor.lastName',
              email: '$instructor.email',
            }
          }
        },
        { $project: { instructor: 0 } }
      ]);
    } else {
      // No location - fetch all offline groups
      offlineGroups = await Group.find(offlineQuery)
        .populate('instructor_id', 'firstName lastName email')
        .sort({ created_at: -1 })
        .lean();
    }

    // Fetch all online groups (no distance)
    onlineGroups = await Group.find(onlineQuery)
      .populate('instructor_id', 'firstName lastName email')
      .sort({ created_at: -1 })
      .lean();

    // Combine results
    let allGroups = [...offlineGroups, ...onlineGroups];

    // Apply pagination
    const total = allGroups.length;
    const paginatedGroups = allGroups.slice(skip, skip + limitNum);

    // Add location_text virtual
    const groupsWithVirtuals = paginatedGroups.map(group => ({
      ...group,
      location_text: (group.groupType === 'offline' && group.location) 
        ? group.location.address 
        : null,
      id: group._id,
    }));

    res.json({
      success: true,
      data: {
        groups: groupsWithVirtuals,
        pagination: {
          current: pageNum,
          pages: Math.ceil(total / limitNum),
          total,
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


router.get('/my-groups', auth, async (req, res) => {
  try {
    // 1. Find all memberships for the current user
    const memberships = await GroupMember.find({ user_id: req.user.id });

    // 2. Extract just the group IDs from the memberships
    const groupIds = memberships.map(m => m.group_id);

    // 3. Find all groups that match those IDs and populate the instructor's name
    const groups = await Group.find({ '_id': { $in: groupIds } })
      .populate('instructor_id', 'fullName');

    res.json({ success: true, data: { groups } });
  } catch (error) {
    console.error('Error fetching user groups:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Get group by ID (This one can still populate for detail views)
// ==================== GET SINGLE GROUP ====================
router.get('/:id', async (req, res) => {
  try {
    const group = await Group.findById(req.params.id)
      .populate('instructor_id', 'firstName lastName email')
      .lean(); // Add .lean() to get plain object
    
    if (!group) {
      return res.status(404).json({
        success: false,
        message: 'Group not found'
      });
    }

    // Add location_text virtual and member count
    const groupData = {
      ...group,
      location_text: (group.groupType === 'offline' && group.location) 
        ? group.location.address 
        : null,
      id: group._id.toString(),
    };
    
    // Add member count
    const memberCount = await GroupMember.countDocuments({ group_id: group._id });
    groupData.memberCount = memberCount;

    // CRITICAL FIX: Ensure meetLink is always present for online groups
    if (group.groupType === 'online') {
      groupData.meetLink = group.meetLink || null;
    }

    res.json({
      success: true,
      data: groupData
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

// REPLACE your existing router.post('/',...) with this entire block
router.post('/', auth, async (req, res) => {
    try {
        const {
            group_name,
            groupType,
            location_text,
            latitude,
            longitude,
            schedule,
            color,
            description,
            yoga_style,
            difficulty_level,
            price_per_session,
            max_participants,
            meetLink,
        } = req.body;

        const instructor_id = req.user.id;

        // --- Validation (More Robust) ---
        if (!schedule || !schedule.startTime || !schedule.endTime || !schedule.days || !schedule.startDate || !schedule.endDate) {
            return res.status(400).json({ success: false, message: 'A complete schedule object is required (startTime, endTime, days, startDate, endDate).' });
        }
        if (new Date(schedule.endDate) < new Date(schedule.startDate)) {
            return res.status(400).json({ success: false, message: 'Schedule end date cannot be before the start date.' });
        }

        // --- Create the Group ---
        const groupData = {
            instructor_id,
            group_name,
            groupType,
            color,
            schedule,
            description,
            yoga_style,
            difficulty_level,
            price_per_session: parseFloat(price_per_session) || 0,
            max_participants: parseInt(max_participants) || 20,
            meetLink: groupType === 'online' ? meetLink : null,
        };

        if (groupType === 'offline') {
          if (!latitude || !longitude || !location_text) {
              return res.status(400).json({ success: false, message: 'For offline groups, latitude, longitude, and location text are required.' });
          }
          groupData.location = {
              type: 'Point',
              coordinates: [parseFloat(longitude), parseFloat(latitude)],
              address: location_text
          };
          groupData.location_text = location_text;
          groupData.latitude = parseFloat(latitude);
          groupData.longitude = parseFloat(longitude);
        }

        const group = new Group(groupData);
        await group.save();

        res.status(201).json({
            success: true,
            message: `Group created successfully!`,
            data: group
        });

    } catch (error) {
        console.error('Create group error:', error);
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
router.put('/:id', auth, async (req, res) => {
  try {
    const groupId = req.params.id;
    
    // Find existing group
    const existingGroup = await Group.findById(groupId);
    if (!existingGroup) {
      return res.status(404).json({
        success: false,
        message: 'Group not found'
      });
    }

    // Check authorization
    if (existingGroup.instructor_id.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this group'
      });
    }

    const {
      group_name,
      groupType,
      latitude,
      longitude,
      location_text,
      schedule,
      yoga_style,
      difficulty_level,
      description,
      max_participants,
      price_per_session,
      currency,
      requirements,
      equipment_needed,
      is_active,
      color,
      meetLink,
    } = req.body;

    const updateData = {};
    const unsetData = {};

    // Update basic fields if provided
    if (group_name !== undefined) updateData.group_name = group_name;
    if (groupType !== undefined) updateData.groupType = groupType;
    if (schedule !== undefined) updateData.schedule = schedule;
    if (yoga_style !== undefined) updateData.yoga_style = yoga_style;
    if (difficulty_level !== undefined) updateData.difficulty_level = difficulty_level;
    if (description !== undefined) updateData.description = description;
    if (max_participants !== undefined) updateData.max_participants = max_participants;
    if (price_per_session !== undefined) updateData.price_per_session = price_per_session;
    if (currency !== undefined) updateData.currency = currency;
    if (requirements !== undefined) updateData.requirements = requirements;
    if (equipment_needed !== undefined) updateData.equipment_needed = equipment_needed;
    if (is_active !== undefined) updateData.is_active = is_active;
    if (color !== undefined) updateData.color = color;

    // Determine final groupType
    const finalGroupType = groupType || existingGroup.groupType;

    // Handle location/meetLink based on groupType
    if (finalGroupType === 'offline') {
      // Update location if all coordinates provided
      if (latitude && longitude && location_text) {
        updateData.location = {
          type: 'Point',
          coordinates: [parseFloat(longitude), parseFloat(latitude)],
          address: location_text
        };
      }
      // Clear meetLink for offline groups
      unsetData.meetLink = '';
      
    } else if (finalGroupType === 'online') {
      // Update meetLink if provided
      if (meetLink !== undefined) {
        updateData.meetLink = meetLink;
      }
      // Clear location for online groups
      unsetData.location = '';
    }

    // Build update query
    const updateQuery = { $set: updateData };
    if (Object.keys(unsetData).length > 0) {
      updateQuery.$unset = unsetData;
    }

    // Perform update
    const updatedGroup = await Group.findByIdAndUpdate(
      groupId,
      updateQuery,
      { new: true, runValidators: true }
    ).populate('instructor_id', 'firstName lastName email');

    res.json({
      success: true,
      message: 'Group updated successfully',
      data: updatedGroup
    });

  } catch (error) {
    console.error('Update group error:', error);
    if (error.name === 'ValidationError') {
      return res.status(400).json({
        success: false,
        message: 'Group validation failed',
        error: error.message
      });
    }
    res.status(500).json({
      success: false,
      message: 'Failed to update group',
      error: error.message
    });
  }
});
// // ADD THIS NEW ROUTE
// router.get('/:id/sessions', async (req, res) => {
//   try {
//     const group = await Group.findById(req.params.id);

//     if (!group) {
//       return res.status(404).json({ success: false, message: 'Group not found' });
//     }
//     if (!group.schedule || !group.schedule.startDate || !group.schedule.endDate || !group.schedule.days) {
//       return res.status(400).json({ success: false, message: 'Group does not have a valid schedule.' });
//     }

//     const { startDate, endDate, days, startTime } = group.schedule;
//     const sessions = [];
    
//     const dayNameToNum = { 'Sunday': 0, 'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4, 'Friday': 5, 'Saturday': 6 };
//     const scheduledDays = days.map(d => dayNameToNum[d]);
    
//     let currentDate = new Date(startDate);
//     const finalDate = new Date(endDate);
    
//     const [startHour, startMinute] = startTime.split(':').map(Number);

//     while (currentDate <= finalDate) {
//       if (scheduledDays.includes(currentDate.getDay())) {
//         const sessionDate = new Date(currentDate);
//         // Set the time from the schedule, preserving the date's timezone offset
//         sessionDate.setHours(startHour, startMinute, 0, 0);
//         sessions.push(sessionDate.toISOString());
//       }
//       currentDate.setDate(currentDate.getDate() + 1);
//     }

//     res.json({ success: true, data: { sessions } });

//   } catch (error) {
//     console.error('Get sessions error:', error);
//     res.status(500).json({ success: false, message: 'Failed to calculate sessions', error: error.message });
//   }
// });

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
router.post('/:id/join', auth, async (req, res) => {
  try {
    // Get user details from the authenticated request (provided by 'auth' middleware)
    const user_id = req.user.id; // Use .id (often added by JWT decoding) or req.user._id if that's what your middleware provides
    const joiningUserName = req.user.fullName; // Assumes fullName virtual exists on User model
    const group_id = req.params.id;

    // 1. Fetch group details to get instructor ID and group name
    const group = await Group.findById(group_id);
    if (!group) {
        return res.status(404).json({ success: false, message: 'Group not found' });
    }
    const instructorId = group.instructor_id ? group.instructor_id.toString() : null; // Convert ObjectId to string
    const groupName = group.group_name;

    // 2. Check if user is already a member
    const existingMember = await GroupMember.findOne({ user_id, group_id });
    if (existingMember) {
      return res.status(400).json({
        success: false,
        message: 'User is already a member of this group'
      });
    }

    // 3. Add the user to the group
    const membership = new GroupMember({ user_id, group_id });
    await membership.save();

    // --- Send Notifications ---
    // 4. Notify the instructor (if they exist and aren't the one joining)
    if (instructorId && instructorId !== user_id) {
        // console.log(`Attempting to notify instructor ${instructorId} about ${joiningUserName} joining ${groupName}`); // Debug log
        await sendNotificationToUser(
            instructorId,
            'New Member Joined!', // Notification Title
            `${joiningUserName} has joined your group "${groupName}".`, // Notification Body
            { type: 'new_member', groupId: group_id } // Optional data payload
        );
    }

    // 5. Notify the participant who just joined
    // console.log(`Attempting to notify participant ${user_id} about joining ${groupName}`); // Debug log
    await sendNotificationToUser(
        user_id,
        'Welcome!', // Notification Title
        `Hurray!! "${GroupMember}" : You have successfully joined the group!!`, // Notification Body
        { type: 'group_joined', groupId: group_id } // Optional data payload
    );
    // --- End Notifications ---

    // 6. Send success response
    res.status(201).json({
      success: true,
      message: `Successfully joined the group, "${groupName}"`,
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
// GET reverse geocode coordinates to an address
// GET reverse geocode coordinates to an address
router.get('/location/reverse-geocode', async (req, res) => {
  const { lat, lon } = req.query;
  if (!lat || !lon) {
    return res.status(400).json({ success: false, message: 'Latitude and longitude are required.' });
  }

  try {
    const reverseGeocodeUrl = `https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${lat}&lon=${lon}`;
    const response = await axios.get(reverseGeocodeUrl, {
      headers: { 'User-Agent': 'YogaApp/1.0' }
    });

    const fullAddress = response.data.display_name || 'Unknown location';
    const addressDetails = response.data.address;
    
    // Find the city from the address details, looking for 'city', 'town', or 'village'
    const city = addressDetails.city || addressDetails.town || addressDetails.village || '';

    res.json({ success: true, data: { address: fullAddress, city: city } });

  } catch (error) {
    console.error('Reverse geocoding error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch address.' });
  }
});

module.exports = router;