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
    const { search, latitude, longitude, page = 1, limit = 10, instructor_id } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    let searchCoords;

    // --- Geocoding Logic (no changes) ---
    if (search) {
      try {
        const geocodeUrl = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(search)}&format=json&limit=1`;
        const geocodeResponse = await axios.get(geocodeUrl, {
          headers: { 'User-Agent': 'YogaApp/1.0' }
        });
        if (geocodeResponse.data && geocodeResponse.data.length > 0) {
          searchCoords = [
            parseFloat(geocodeResponse.data[0].lon),
            parseFloat(geocodeResponse.data[0].lat),
          ];
        }
      } catch (e) {
        console.error('Geocoding failed for search term:', search);
      }
    }
    if (!searchCoords && latitude && longitude) {
      searchCoords = [parseFloat(longitude), parseFloat(latitude)];
    }
    // --- End of Geocoding Logic ---

    // --- Build Text/ID Match Conditions ---
    const baseMatchConditions = {};
    if (instructor_id) {
      // Ensure instructor_id is converted to ObjectId for matching
      baseMatchConditions.instructor_id = new mongoose.Types.ObjectId(instructor_id);
    }
    if (search) {
      baseMatchConditions.$or = [
        { group_name: { $regex: search, $options: 'i' } },
        // Use the new virtual field in the search
        { 'location.address': { $regex: search, $options: 'i' } }, 
        { description: { $regex: search, $options: 'i' } },
        { yoga_style: { $regex: search, $options: 'i' } },
      ];
    }
    
    // --- Main Aggregation Pipeline ---
    const pipeline = [];

    // 1. We use $facet to run two queries in parallel
    pipeline.push({
      $facet: {
        // --- FACET 1: Offline Groups (Geospatial) ---
        "offlineGroups": [
          ...(searchCoords ? [{
            // If coords are provided, $geoNear is the *best* first filter.
            $geoNear: {
              near: { type: 'Point', coordinates: searchCoords },
              distanceField: 'distance',
              spherical: true,
              maxDistance: 50000, // 50km
              // We also filter by text/ID *during* the geo-search for efficiency
              query: {
                ...baseMatchConditions,
                groupType: 'offline' // Only search offline groups
              }
            }
          }] : [
            // If no coords, just do a normal match for offline groups
            { $match: { ...baseMatchConditions, groupType: 'offline' } },
            { $sort: { created_at: -1 } } // Add a default sort
          ]),
          // Populate instructor for offline groups
          { $lookup: { from: 'users', localField: 'instructor_id', foreignField: '_id', as: 'instructor' } },
          { $unwind: { path: '$instructor', preserveNullAndEmptyArrays: true } }
        ],
        
        // --- FACET 2: Online Groups (Text/ID only) ---
        // These are *always* returned if they match the text/ID, location is irrelevant
        "onlineGroups": [
          {
            $match: {
              ...baseMatchConditions,
              groupType: 'online' // Only search online groups
            }
          },
          { $sort: { created_at: -1 } },
          // Populate instructor for online groups
          { $lookup: { from: 'users', localField: 'instructor_id', foreignField: '_id', as: 'instructor' } },
          { $unwind: { path: '$instructor', preserveNullAndEmptyArrays: true } }
        ]
      }
    });

    // 2. Combine the results from both facets
    pipeline.push({
      $project: {
        allGroups: { $concatArrays: ["$offlineGroups", "$onlineGroups"] }
      }
    });
    pipeline.push({ $unwind: "$allGroups" });
    pipeline.push({ $replaceRoot: { newRoot: "$allGroups" } });
    
    // 3. We must re-sort *after* merging, prioritizing distance if it exists
    pipeline.push({
      $sort: {
        distance: 1, // Groups with distance (offline) will come first
        created_at: -1 // Then sort by creation date
      }
    });

    // 4. Apply pagination to the *combined* results
    const countPipeline = [...pipeline, { $count: 'total' }];
    const paginatedPipeline = [
      ...pipeline,
      { $skip: skip },
      { $limit: limitNum },
      // Manual population of instructor (since $lookup returns an array)
      {
        $addFields: {
          "instructor_id": {
            _id: "$instructor._id",
            firstName: "$instructor.firstName",
            lastName: "$instructor.lastName",
            email: "$instructor.email",
          }
        }
      },
      { $project: { instructor: 0 } } // Clean up the temporary instructor object
    ];

    // 5. Execute queries
    const [groups, totalResult] = await Promise.all([
      Group.aggregate(paginatedPipeline),
      Group.aggregate(countPipeline),
    ]);

    const total = totalResult.length > 0 ? totalResult[0].total : 0;
    
    // Manually add the virtual 'location_text' for frontend compatibility
    // because .aggregate() skips virtuals.
    const groupsWithVirtuals = groups.map(group => ({
      ...group,
      location_text: (group.groupType === 'offline' && group.location) ? group.location.address : null,
      id: group._id // ensure 'id' exists
    }));

    res.json({
      success: true,
      data: {
        groups: groupsWithVirtuals, // Send the processed groups
        pagination: {
          current: pageNum,
          pages: Math.ceil(total / limitNum),
          total,
        },
      },
    });

  } catch (error) {
    console.error('Get groups error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch groups', error: error.message });
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