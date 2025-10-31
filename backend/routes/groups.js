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
    // 1. GET ALL QUERY PARAMS (including new 'groupType')
    const {
      search,
      latitude,
      longitude,
      page = 1,
      limit = 10,
      instructor_id,
      groupType = 'all', // 'all', 'offline', 'online'
    } = req.query;

    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    // 2. BUILD BASE TEXT/ID MATCH
    const baseMatchConditions = {};
    if (instructor_id) {
      baseMatchConditions.instructor_id = new mongoose.Types.ObjectId(
        instructor_id,
      );
    }
    if (search) {
      baseMatchConditions.$or = [
        { group_name: { $regex: search, $options: 'i' } },
        { 'location.address': { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
        { yoga_style: { $regex: search, $options: 'i' } },
      ];
    }

    // 3. BUILD THE PIPELINE
    const pipeline = [];
    let searchCoords;

    if (latitude && longitude) {
      searchCoords = [parseFloat(longitude), parseFloat(latitude)];
    }

    // Check if this is a location-based search (user wants 'offline' or 'all' and provides location)
    const isLocationSearch = searchCoords && groupType !== 'online';

    if (isLocationSearch) {
      // --- SCENARIO 1: LOCATION-BASED SEARCH (Nearby) ---
      // This *only* returns offline groups, sorted by distance.
      pipeline.push({
        $geoNear: {
          near: { type: 'Point', coordinates: searchCoords },
          distanceField: 'distance',
          spherical: true,
          maxDistance: 50000, // 50km
          query: {
            ...baseMatchConditions,
            groupType: 'offline', // $geoNear requires a location, so only offline
          },
        },
      });
      // We add a match for base conditions *again* just in case the query optimizer
      // doesn't catch it in $geoNear
      pipeline.push({ $match: { ...baseMatchConditions, groupType: 'offline' } });

    } else {
      // --- SCENARIO 2: TEXT-BASED SEARCH (No location or Online-only) ---
      // This search is sorted by date, not distance.
      
      if (groupType === 'online') {
        baseMatchConditions.groupType = 'online';
      } else if (groupType === 'offline') {
        baseMatchConditions.groupType = 'offline';
      }
      // If groupType is 'all', we add no filter, so it finds both.

      pipeline.push({ $match: baseMatchConditions });
      pipeline.push({ $sort: { created_at: -1 } });
    }

    // 4. COMMON STAGES: Populate, Paginate, and Execute
    
    // Create count pipeline *before* pagination
    const countPipeline = [...pipeline, { $count: 'total' }];

    // Add pagination and instructor lookup to main pipeline
    pipeline.push(
      { $skip: skip },
      { $limit: limitNum },
      {
        $lookup: {
          from: 'users',
          localField: 'instructor_id',
          foreignField: '_id',
          as: 'instructor',
        },
      },
      { $unwind: { path: '$instructor', preserveNullAndEmptyArrays: true } },
      {
        $addFields: {
          'instructor_id': {
            _id: '$instructor._id',
            firstName: '$instructor.firstName',
            lastName: '$instructor.lastName',
            email: '$instructor.email',
          },
        },
      },
      { $project: { instructor: 0 } },
    );

    // 5. EXECUTE QUERIES
    const [groups, totalResult] = await Promise.all([
      Group.aggregate(pipeline),
      Group.aggregate(countPipeline),
    ]);

    const total = totalResult.length > 0 ? totalResult[0].total : 0;

    // Manually add virtuals (aggregate skips them)
    const groupsWithVirtuals = groups.map(group => ({
      ...group,
      location_text: (group.groupType === 'offline' && group.location) ? group.location.address : null,
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
        },
      },
    });
  } catch (error) {
    console.error('Get groups error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch groups',
      error: error.message,
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
router.put('/:id', auth, async (req, res) => { // Added auth middleware
  try {
    const { latitude, longitude, schedule, meetLink, ...otherDetails } = req.body;
    const updateData = { ...otherDetails };

    // If latitude and longitude are provided, construct the location object
    if (latitude && longitude) {
      updateData.location = {
        type: 'Point',
        coordinates: [parseFloat(longitude), parseFloat(latitude)],
      };
      updateData.latitude = parseFloat(latitude);
      updateData.longitude = parseFloat(longitude);
    }
    if (schedule) {
        updateData.schedule = schedule;
    }
    if (meetLink) {
        updateData.meetLink = meetLink;
    }

    const group = await Group.findByIdAndUpdate(
      req.params.id,
      { $set: updateData }, // Use $set for safer updates
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
    // Add specific validation error handling
    if (error.name === 'ValidationError') {
      return res.status(400).json({ success: false, message: 'Group validation failed', error: error.message });
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
        `You have successfully joined the group "${groupName}".`, // Notification Body
        { type: 'group_joined', groupId: group_id } // Optional data payload
    );
    // --- End Notifications ---

    // 6. Send success response
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