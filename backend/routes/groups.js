// backend/routes/groups.js

const express = require('express');
const Group = require('../model/Group');
const GroupMember = require('../model/GroupMember');
const router = express.Router();
const auth = require('../middleware/auth');
const axios = require('axios');

// const Session = require('../model/Session');
const crypto = require('crypto');

// Get all groups
router.get('/', async (req, res) => {
  try {
    // 1. Destructure all possible query parameters
    const { search, latitude, longitude, page = 1, limit = 10, instructor_id } = req.query;

    let searchCoords;

    // --- Geocoding Logic (no changes needed here) ---
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

    // Scenario 1: Geospatial search (if coordinates are available)
    if (searchCoords) {
      const pipeline = [
        {
          $geoNear: {
            near: {
              type: 'Point',
              coordinates: searchCoords,
            },
            distanceField: 'distance',
            spherical: true,
            maxDistance: 50000, // 50km radius
          },
        },
      ];
      
      // ✅ Dynamically build the matching conditions
      const matchConditions = {};
      if (instructor_id) {
        matchConditions.instructor_id = instructor_id;
      }
      if (search) {
        matchConditions.$or = [
          { group_name: { $regex: search, $options: 'i' } },
          { location_text: { $regex: search, $options: 'i' } },
        ];
      }

      // ✅ Add the match stage to the pipeline ONLY if there are conditions
      if (Object.keys(matchConditions).length > 0) {
        pipeline.push({ $match: matchConditions });
      }

      // --- Population and Pagination (no changes needed here) ---
      pipeline.push({
        $lookup: { from: 'users', localField: 'instructor_id', foreignField: '_id', as: 'instructor_id' }
      }, {
        $unwind: { path: '$instructor_id', preserveNullAndEmptyArrays: true }
      });

      const countPipeline = [...pipeline, { $count: 'total' }];
      const paginatedPipeline = [
        ...pipeline,
        { $skip: (parseInt(page) - 1) * parseInt(limit) },
        { $limit: parseInt(limit) }
      ];

      const [groups, totalResult] = await Promise.all([
        Group.aggregate(paginatedPipeline),
        Group.aggregate(countPipeline),
      ]);
      
      const total = totalResult.length > 0 ? totalResult[0].total : 0;
      
      return res.json({
        success: true,
        data: {
          groups,
          pagination: {
            current: parseInt(page),
            pages: Math.ceil(total / limit),
            total,
          },
        },
      });

    // Scenario 2: Simple text/ID search (no location data)
    } else {
      // ✅ Dynamically build the query object
      const query = {};
      if (instructor_id) {
        query.instructor_id = instructor_id;
      }
      if (search) {
        query.$or = [
          { group_name: { $regex: search, $options: 'i' } },
          { location_text: { $regex: search, $options: 'i' } },
        ];
      }
      
      const total = await Group.countDocuments(query);
      const groups = await Group.find(query)
        .populate('instructor_id', 'fullName')
        .limit(parseInt(limit))
        .skip((parseInt(page) - 1) * parseInt(limit))
        .lean();
      
      return res.json({
        success: true,
        data: {
          groups,
          pagination: {
            current: parseInt(page),
            pages: Math.ceil(total / limit),
            total,
          },
        },
      });
    }

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
            color, // <-- New field
            description,
            yoga_style,
            difficulty_level,
            price_per_session,
            max_participants,
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
            // location: {
            //     type: 'Point',
            //     coordinates: [parseFloat(longitude), parseFloat(latitude)],
            // },
            // location_text,
            // latitude: parseFloat(latitude),
            // longitude: parseFloat(longitude),
            color,
            schedule,
            description,
            yoga_style,
            difficulty_level,
            price_per_session: parseFloat(price_per_session) || 0,
            max_participants: parseInt(max_participants) || 20,
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
    const { latitude, longitude, schedule, ...otherDetails } = req.body;
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