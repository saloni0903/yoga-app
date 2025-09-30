// backend/routes/groups.js

const express = require('express');
const Group = require('../model/Group');
const GroupMember = require('../model/GroupMember');
const router = express.Router();
const auth = require('../middleware/auth');
const axios = require('axios');

// Get all groups
// routes/groups.js

// GET all groups (with advanced search, geocoding, and distance calculation)
router.get('/', async (req, res) => {
  try {
    const { search, latitude, longitude, page = 1, limit = 10 } = req.query;

    let searchCoords;

    // Priority 1: If user provides a search term, geocode it to get coordinates.
    if (search) {
      try {
        const geocodeUrl = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(search)}&format=json&limit=1`;
        const geocodeResponse = await axios.get(geocodeUrl, {
          headers: { 'User-Agent': 'YogaApp/1.0' } // Nominatim requires a User-Agent
        });
        
        if (geocodeResponse.data && geocodeResponse.data.length > 0) {
          searchCoords = [
            parseFloat(geocodeResponse.data[0].lon),
            parseFloat(geocodeResponse.data[0].lat),
          ];
        }
      } catch (e) {
        console.error('Geocoding failed for search term:', search);
        // If geocoding fails, we can fall back to a simple text search without location.
        // Or, for now, we'll proceed without searchCoords.
      }
    }

    // Priority 2: If no search term, use the user's provided coordinates.
    if (!searchCoords && latitude && longitude) {
      searchCoords = [parseFloat(longitude), parseFloat(latitude)];
    }

    // If we have coordinates, perform a geospatial query. Otherwise, do a simple text search.
    if (searchCoords) {
      // Use MongoDB's Aggregation Pipeline for geospatial queries with distance.
      const pipeline = [
        {
          $geoNear: {
            near: {
              type: 'Point',
              coordinates: searchCoords,
            },
            distanceField: 'distance', // This adds a 'distance' field (in meters) to each document
            spherical: true,
            maxDistance: 50000, // Optional: 50km radius
          },
        },
      ];
      
      // If there was a search term, add a match stage after geo-searching.
      if (search) {
        pipeline.push({
          $match: {
            $or: [
              { group_name: { $regex: search, $options: 'i' } },
              { location_text: { $regex: search, $options: 'i' } },
            ],
          },
        });
      }

      // Add instructor population
      pipeline.push({
        $lookup: {
          from: 'users', // The actual collection name for 'User' model
          localField: 'instructor_id',
          foreignField: '_id',
          as: 'instructor_id'
        }
      }, {
        $unwind: { // Deconstruct the instructor_id array
          path: '$instructor_id',
          preserveNullAndEmptyArrays: true // Keep groups even if instructor is not found
        }
      });

      const paginatedPipeline = [
        ...pipeline,
        { $skip: (parseInt(page) - 1) * parseInt(limit) },
        { $limit: parseInt(limit) }
      ];

      const countPipeline = [...pipeline, { $count: 'total' }];

      const [groups, totalResult] = await Promise.all([
        Group.aggregate(paginatedPipeline),
        Group.aggregate(countPipeline),
      ]);
      
      const total = totalResult.length > 0 ? totalResult[0].total : 0;
      
      res.json({
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

    } else {
      // Fallback to simple text search if no location data is available
      let query = {};
      if (search) {
        query.$or = [
          { group_name: { $regex: search, $options: 'i' } },
          { location_text: { $regex: search, $options: 'i' } },
        ];
      }
      const groups = await Group.find(query).populate('instructor_id', 'fullName').limit(parseInt(limit)).skip((page - 1) * parseInt(limit)).lean();
      const total = await Group.countDocuments(query);
      res.json({
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
      location: {
        type: 'Point',
        coordinates: [parseFloat(longitude), parseFloat(latitude)], // [lon, lat]
      },
      location_text,
      latitude: parseFloat(latitude), // <-- ADD THIS LINE
      longitude: parseFloat(longitude), // <-- ADD THIS LINE
      timings_text,
      description,
      yoga_style,
      difficulty_level,
      session_duration: parseInt(session_duration) || 60,
      price_per_session: parseFloat(price_per_session) || 0,
      max_participants: parseInt(max_participants) || 20,
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
    const { latitude, longitude, ...otherDetails } = req.body;
    const updateData = { ...otherDetails };

    // If latitude and longitude are provided, construct the location object
    if (latitude && longitude) {
      updateData.location = {
        type: 'Point',
        coordinates: [parseFloat(longitude), parseFloat(latitude)],
      };
    }

    const group = await Group.findByIdAndUpdate(
      req.params.id,
      updateData, // Use the prepared updateData object
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