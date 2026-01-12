// backend/routes/users.js
const express = require('express');
const User = require('../model/User');
const auth = require('../middleware/auth');
const { Op } = require('sequelize');
const router = express.Router();

function parseJsonMaybe(value) {
  if (typeof value !== 'string') return value;
  const trimmed = value.trim();
  if (!trimmed) return value;
  if ((trimmed.startsWith('{') && trimmed.endsWith('}')) || (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
    try {
      return JSON.parse(trimmed);
    } catch {
      return value;
    }
  }
  return value;
}

// Get all users (admin only)
router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 10, role, search, location } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const offset = (pageNum - 1) * limitNum;

    const where = {};
    if (role) where.role = role;
    if (location) where.location = { [Op.iLike]: `%${location}%` };
    if (search) {
      where[Op.or] = [
        { firstName: { [Op.iLike]: `%${search}%` } },
        { lastName: { [Op.iLike]: `%${search}%` } },
        { email: { [Op.iLike]: `%${search}%` } },
      ];
    }

    const { rows: users, count: total } = await User.findAndCountAll({
      where,
      order: [['createdAt', 'DESC']],
      limit: limitNum,
      offset,
    });

    res.json({
      success: true,
      data: {
        users,
        pagination: {
          current: pageNum,
          pages: Math.ceil(total / limitNum),
          total
        }
      }
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch users',
      error: error.message
    });
  }
});

// Get users by location
router.get('/location/:location', async (req, res) => {
  try {
    const { location } = req.params;
    const { page = 1, limit = 10, role } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const offset = (pageNum - 1) * limitNum;

    const where = {
      location: { [Op.iLike]: `%${location}%` },
    };
    if (role) where.role = role;

    const { rows: users, count: total } = await User.findAndCountAll({
      where,
      order: [['createdAt', 'DESC']],
      limit: limitNum,
      offset,
    });

    res.json({
      success: true,
      data: {
        users,
        location,
        pagination: {
          current: pageNum,
          pages: Math.ceil(total / limitNum),
          total
        }
      }
    });
  } catch (error) {
    console.error('Get users by location error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch users by location',
      error: error.message
    });
  }
});

// Get instructors by location
router.get('/instructors/location/:location', async (req, res) => {
  try {
    const { location } = req.params;
    const { page = 1, limit = 10 } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const offset = (pageNum - 1) * limitNum;

    const where = {
      role: 'instructor',
      location: { [Op.iLike]: `%${location}%` },
    };

    const { rows: instructors, count: total } = await User.findAndCountAll({
      where,
      order: [['createdAt', 'DESC']],
      limit: limitNum,
      offset,
    });

    res.json({
      success: true,
      data: {
        instructors,
        location,
        pagination: {
          current: pageNum,
          pages: Math.ceil(total / limitNum),
          total
        }
      }
    });
  } catch (error) {
    console.error('Get instructors by location error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch instructors by location',
      error: error.message
    });
  }
});

// Get user by ID
router.get('/:id', async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user',
      error: error.message
    });
  }
});
const multer = require('multer');
const upload = multer(); // Using basic in-memory storage

// Update user profile
router.put('/:id', upload.single('profileImage'), async (req, res) => {
  try {
    // Destructure all possible text fields from the multipart body
    const { firstName, lastName, phone, samagraId, location, dateOfBirth, emergencyContact, medicalInfo, preferences } = req.body;
    
    // The uploaded file (if any) is available in req.file
    const profileImageFile = req.file;

    const updateData = {};
    if (firstName) updateData.firstName = firstName;
    if (lastName) updateData.lastName = lastName;
    if (phone) updateData.phone = phone;
    if (samagraId) updateData.samagraId = samagraId;
    if (location) updateData.location = location; // Added location field
    if (dateOfBirth) updateData.dateOfBirth = dateOfBirth;
    if (emergencyContact) updateData.emergencyContact = parseJsonMaybe(emergencyContact);
    if (medicalInfo) updateData.medicalInfo = parseJsonMaybe(medicalInfo);
    if (preferences) updateData.preferences = parseJsonMaybe(preferences);

    if (profileImageFile) {
      // In a real application, you would upload this file to a cloud storage
      // service (like AWS S3, Google Cloud Storage, or Cloudinary)
      // and get a public URL back. For now, we'll just log it.
      console.log('Received profile image:', profileImageFile.originalname);
      // Example: updateData.profileImage = 'URL_from_cloud_storage';
    }

    await User.update(updateData, { where: { id: req.params.id } });
    const user = await User.findByPk(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      message: 'User updated successfully',
      data: user
    });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update user',
      error: error.message
    });
  }
});

// Delete user
router.delete('/:id', async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (user) {
      await user.destroy();
    }
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete user',
      error: error.message
    });
  }
});

// Notifications
router.put('/me/fcm-token', auth, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    const userId = req.user.id; // From the 'auth' middleware

    if (!fcmToken) {
      return res.status(400).json({ success: false, message: 'fcmToken is required.' });
    }

    const user = await User.findByPk(userId);
    if (user) {
      const existing = Array.isArray(user.fcmTokens) ? user.fcmTokens : [];
      if (!existing.includes(fcmToken)) {
        user.fcmTokens = [...existing, fcmToken];
        await user.save();
      }
    }

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    res.json({ success: true, message: 'FCM token updated successfully.' });

  } catch (error) {
    console.error('Error updating FCM token:', error);
    res.status(500).json({ success: false, message: 'Server error.' });
  }
});

module.exports = router;
