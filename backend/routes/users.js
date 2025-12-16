// backend/routes/users.js
const express = require('express');
const User = require('../model/User');
const auth = require('../middleware/auth');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    // Check if directory exists, if not create it
    const uploadDir = 'uploads/';
    if (!fs.existsSync(uploadDir)){
        fs.mkdirSync(uploadDir);
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    // Create unique filename: user-id-timestamp.ext
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

// Filter to accept only images
const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Not an image!'), false);
  }
};

const upload = multer({ 
  storage: storage,
  limits: { fileSize: 1024 * 1024 * 5 }, // Limit 5MB
  fileFilter: fileFilter
});

// Get all users (admin only)
router.get('/', async (req, res) => {
  try {
    const { page = 1, limit = 10, role, search, location } = req.query;
    const query = {};

    if (role) {
      query.role = role;
    }

    if (location) {
      query.location = { $regex: location, $options: 'i' };
    }

    if (search) {
      query.$or = [
        { firstName: { $regex: search, $options: 'i' } },
        { lastName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } }
      ];
    }

    const users = await User.find(query)
      .select('-password')
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ createdAt: -1 });

    const total = await User.countDocuments(query);

    res.json({
      success: true,
      data: {
        users,
        pagination: {
          current: parseInt(page),
          pages: Math.ceil(total / limit),
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
    const query = {
      location: { $regex: location, $options: 'i' }
    };

    if (role) {
      query.role = role;
    }

    const users = await User.find(query)
      .select('-password')
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ createdAt: -1 });

    const total = await User.countDocuments(query);

    res.json({
      success: true,
      data: {
        users,
        location,
        pagination: {
          current: parseInt(page),
          pages: Math.ceil(total / limit),
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

    const instructors = await User.find({
      role: 'instructor',
      location: { $regex: location, $options: 'i' }
    })
      .select('-password')
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ createdAt: -1 });

    const total = await User.countDocuments({
      role: 'instructor',
      location: { $regex: location, $options: 'i' }
    });

    res.json({
      success: true,
      data: {
        instructors,
        location,
        pagination: {
          current: parseInt(page),
          pages: Math.ceil(total / limit),
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
    const user = await User.findById(req.params.id).select('-password');
    
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
// const multer = require('multer');
// const upload = multer(); // Using basic in-memory storage

// Update user profile
router.put('/:id', upload.single('profileImage'), async (req, res) => {
  try {
    const { firstName, lastName, phone, samagraId, location, dateOfBirth } = req.body;
    
    // Parse JSON strings if they come as strings (common in Multipart requests)
    let preferences, emergencyContact, medicalInfo;
    try {
        if(req.body.preferences) preferences = JSON.parse(req.body.preferences);
        if(req.body.emergencyContact) emergencyContact = JSON.parse(req.body.emergencyContact);
        if(req.body.medicalInfo) medicalInfo = JSON.parse(req.body.medicalInfo);
    } catch(e) {
        console.log("JSON Parse error for nested fields", e);
    }

    const updateData = {};
    if (firstName) updateData.firstName = firstName;
    if (lastName) updateData.lastName = lastName;
    if (phone) updateData.phone = phone;
    if (samagraId) updateData.samagraId = samagraId;
    if (location) updateData.location = location;
    if (dateOfBirth) updateData.dateOfBirth = dateOfBirth;
    if (emergencyContact) updateData.emergencyContact = emergencyContact;
    if (medicalInfo) updateData.medicalInfo = medicalInfo;
    if (preferences) updateData.preferences = preferences;

    // 3. Handle the Image File
    if (req.file) {
      // Normalize path to use forward slashes (works for Windows/Linux)
      // Stores: uploads/filename.jpg
      updateData.profileImage = req.file.path.replace(/\\/g, "/"); 
    }

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { $set: updateData },
      { new: true, runValidators: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
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
    const user = await User.findByIdAndDelete(req.params.id);
    
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

    // Use $addToSet to add the token to the array only if it's not already there.
    // This prevents duplicate tokens for the same device.
    const user = await User.findByIdAndUpdate(
      userId,
      { $addToSet: { fcmTokens: fcmToken } },
      { new: true }
    );

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
