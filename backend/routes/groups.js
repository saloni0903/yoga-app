// backend/routes/groups.js

const express = require('express');
const Group = require('../model/Group');
const GroupMember = require('../model/GroupMember');
const router = express.Router();
const auth = require('../middleware/auth');
const axios = require('axios');
const { Op } = require('sequelize');
const sequelize = require('../config/sequelize');

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

    const baseWhere = {};
    if (instructor_id) {
      baseWhere.instructor_id = instructor_id;
    }

    if (search) {
      baseWhere[Op.or] = [
        { group_name: { [Op.iLike]: `%${search}%` } },
        { location_address: { [Op.iLike]: `%${search}%` } },
        { description: { [Op.iLike]: `%${search}%` } },
        { yoga_style: { [Op.iLike]: `%${search}%` } },
      ];
    }

    const offlineWhere = { ...baseWhere, groupType: 'offline' };
    const onlineWhere = { ...baseWhere, groupType: 'online' };

    const Instructor = sequelize.models.User;
    let offlineGroups = [];
    let onlineGroups = [];

    const lat = latitude != null ? Number(latitude) : null;
    const lon = longitude != null ? Number(longitude) : null;
    const hasCoords = Number.isFinite(lat) && Number.isFinite(lon);

    if (hasCoords) {
      // Use a SQL query to compute distance (meters) without PostGIS.
      const replacements = {
        lat,
        lon,
        searchLike: search ? `%${search}%` : null,
        instructorId: instructor_id || null,
      };

      const searchSql = search
        ? 'AND (g.group_name ILIKE :searchLike OR g.location_address ILIKE :searchLike OR g.description ILIKE :searchLike OR g.yoga_style ILIKE :searchLike)'
        : '';
      const instructorSql = instructor_id ? 'AND g.instructor_id = :instructorId' : '';

      const [rows] = await sequelize.query(
        `
          SELECT * FROM (
            SELECT
              g.*,
              (6371000 * acos(
                cos(radians(:lat)) * cos(radians(g.latitude)) *
                cos(radians(g.longitude) - radians(:lon)) +
                sin(radians(:lat)) * sin(radians(g.latitude))
              )) AS distance,
              jsonb_build_object(
                '_id', u.id,
                'firstName', u."firstName",
                'lastName', u."lastName",
                'email', u.email
              ) AS instructor_obj
            FROM groups g
            LEFT JOIN users u ON u.id = g.instructor_id
            WHERE g."groupType" = 'offline'
              ${instructorSql}
              ${searchSql}
              AND g.latitude IS NOT NULL
              AND g.longitude IS NOT NULL
          ) t
          WHERE t.distance <= 50000
          ORDER BY t.created_at DESC
        `,
        { replacements }
      );

      offlineGroups = rows.map(r => ({
        ...r,
        _id: r.id,
        id: r.id,
        instructor_id: r.instructor_obj,
        location_text: r.groupType === 'offline' ? (r.location_address || r.location?.address || null) : null,
      }));
    } else {
      const results = await Group.findAll({
        where: offlineWhere,
        include: [
          {
            model: Instructor,
            as: 'instructor',
            attributes: ['id', 'firstName', 'lastName', 'email'],
          },
        ],
        order: [['created_at', 'DESC']],
      });

      offlineGroups = results.map(g => {
        const obj = g.toJSON();
        return {
          ...obj,
          instructor_id: obj.instructor
            ? { _id: obj.instructor.id, firstName: obj.instructor.firstName, lastName: obj.instructor.lastName, email: obj.instructor.email }
            : obj.instructor_id,
          instructor: undefined,
          location_text: obj.location_text,
        };
      });
    }

    const onlineResults = await Group.findAll({
      where: onlineWhere,
      include: [
        {
          model: Instructor,
          as: 'instructor',
          attributes: ['id', 'firstName', 'lastName', 'email'],
        },
      ],
      order: [['created_at', 'DESC']],
    });

    onlineGroups = onlineResults.map(g => {
      const obj = g.toJSON();
      return {
        ...obj,
        instructor_id: obj.instructor
          ? { _id: obj.instructor.id, firstName: obj.instructor.firstName, lastName: obj.instructor.lastName, email: obj.instructor.email }
          : obj.instructor_id,
        instructor: undefined,
        location_text: obj.location_text,
      };
    });

    const allGroups = [...offlineGroups, ...onlineGroups];
    const total = allGroups.length;
    const paginatedGroups = allGroups.slice(skip, skip + limitNum);

    res.json({
      success: true,
      data: {
        groups: paginatedGroups,
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
    const memberships = await GroupMember.findAll({ where: { user_id: req.user.id } });

    // 2. Extract just the group IDs from the memberships
    const groupIds = memberships.map(m => m.group_id);

    // 3. Find all groups that match those IDs and populate the instructor's name
    const Instructor = sequelize.models.User;
    const groups = await Group.findAll({
      where: { id: { [Op.in]: groupIds } },
      include: [{ model: Instructor, as: 'instructor', attributes: ['id', 'firstName', 'lastName'] }],
      order: [['created_at', 'DESC']],
    });

    const data = groups.map(g => {
      const obj = g.toJSON();
      return {
        ...obj,
        instructor_id: obj.instructor ? { _id: obj.instructor.id, fullName: `${obj.instructor.firstName} ${obj.instructor.lastName}`.trim() } : obj.instructor_id,
        instructor: undefined,
      };
    });

    res.json({ success: true, data: { groups: data } });
  } catch (error) {
    console.error('Error fetching user groups:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Get group by ID (This one can still populate for detail views)
// ==================== GET SINGLE GROUP ====================
router.get('/:id', async (req, res) => {
  try {
    const Instructor = sequelize.models.User;
    const group = await Group.findByPk(req.params.id, {
      include: [{ model: Instructor, as: 'instructor', attributes: ['id', 'firstName', 'lastName', 'email'] }],
    });
    
    if (!group) {
      return res.status(404).json({
        success: false,
        message: 'Group not found'
      });
    }

    const groupObj = group.toJSON();
    const groupData = {
      ...groupObj,
      instructor_id: groupObj.instructor
        ? { _id: groupObj.instructor.id, firstName: groupObj.instructor.firstName, lastName: groupObj.instructor.lastName, email: groupObj.instructor.email }
        : groupObj.instructor_id,
      instructor: undefined,
      id: groupObj.id,
      _id: groupObj.id,
      location_text: groupObj.location_text,
    };
    
    // Add member count
    const memberCount = await GroupMember.count({ where: { group_id: groupObj.id } });
    groupData.memberCount = memberCount;

    // CRITICAL FIX: Ensure meetLink is always present for online groups
    if (groupObj.groupType === 'online') {
      groupData.meetLink = groupObj.meetLink || null;
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
          groupData.location_address = location_text;
          groupData.latitude = parseFloat(latitude);
          groupData.longitude = parseFloat(longitude);
        }

        const group = await Group.create(groupData);

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
    const existingGroup = await Group.findByPk(groupId);
    if (!existingGroup) {
      return res.status(404).json({
        success: false,
        message: 'Group not found'
      });
    }

    // Check authorization
    if (String(existingGroup.instructor_id) !== String(req.user.id)) {
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
        updateData.location_address = location_text;
        updateData.latitude = parseFloat(latitude);
        updateData.longitude = parseFloat(longitude);
      }
      // Clear meetLink for offline groups
      updateData.meetLink = null;
      
    } else if (finalGroupType === 'online') {
      // Update meetLink if provided
      if (meetLink !== undefined) {
        updateData.meetLink = meetLink;
      }
      // Clear location for online groups
      updateData.location = null;
      updateData.location_address = null;
      updateData.latitude = null;
      updateData.longitude = null;
    }

    await existingGroup.update(updateData);

    const Instructor = sequelize.models.User;
    const updatedGroup = await Group.findByPk(groupId, {
      include: [{ model: Instructor, as: 'instructor', attributes: ['id', 'firstName', 'lastName', 'email'] }],
    });

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
    const group = await Group.findByPk(req.params.id);
    
    if (!group) {
      return res.status(404).json({
        success: false,
        message: 'Group not found'
      });
    }

    await group.destroy();

    // Also remove all group members
    await GroupMember.destroy({ where: { group_id: req.params.id } });

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
    const User = sequelize.models.User;
    const members = await GroupMember.findAll({
      where: { group_id: req.params.id, status: 'active' },
      include: [{ model: User, as: 'user', attributes: ['id', 'firstName', 'lastName', 'email', 'phone'] }],
      order: [['joined_at', 'ASC']],
    });
    
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
    const group = await Group.findByPk(group_id);
    if (!group) {
        return res.status(404).json({ success: false, message: 'Group not found' });
    }
    const instructorId = group.instructor_id ? String(group.instructor_id) : null;
    const groupName = group.group_name;

    // 2. Check if user is already a member
    const existingMember = await GroupMember.findOne({ where: { user_id, group_id } });
    if (existingMember) {
      return res.status(400).json({
        success: false,
        message: 'User is already a member of this group'
      });
    }

    // 3. Add the user to the group
    const membership = await GroupMember.create({ user_id, group_id });

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
        `Hurray!! "${groupName}" : You have successfully joined the group!!`, // Notification Body
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

    await GroupMember.update(
      { status: 'left' },
      { where: { user_id, group_id: req.params.id } }
    );

    const membership = await GroupMember.findOne({ where: { user_id, group_id: req.params.id } });

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