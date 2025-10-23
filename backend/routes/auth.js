// backend/routes/auth.js
const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../model/User');
const auth = require('../middleware/auth');  
const router = express.Router();


// ⭐ CHANGE 1: Import and configure multer
const multer = require('multer');
const upload = multer(); // Using a simple in-memory storage for now

// Register
// ⭐ CHANGE 2: Add the multer middleware to the route.
// `upload.single('document')` would be better if you plan to save the file.
// `upload.any()` is a simple way to make it work by just parsing the text fields.
router.post('/register', upload.any(), async (req, res) => {
  try {
    // Because of multer, `req.body` will now be correctly populated with your text fields.
    const { email, password, fullName, role = 'participant', location, phone, samagraId } = req.body;

    // The 'fullName' is sent directly from Flutter, so we split it here.
    const nameParts = fullName.trim().split(' ');
    const firstName = nameParts.shift() || '';
    const lastName = nameParts.join(' ') || '';


    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with this email'
      });
    }

    // Create new user with all fields from Flutter
    const user = new User({
      email,
      password,
      firstName,
      lastName,
      role,
      location,
      phone,
      samagraId
    });

    await user.save();

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id, email: user.email, role: user.role },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: user.toJSON(),
        token
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Registration failed',
      error: error.message
    });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id, email: user.email, role: user.role },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );

    // res.json({
    //   success: true,
    //   message: 'Login successful',
    //   data: {
    //     user: user.toJSON(),
    //     token
    //   }
    // });
    const cookieOptions = {
        httpOnly: true, // Prevents client-side JS from accessing the cookie
        expires: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7-day expiry
        secure: process.env.NODE_ENV === 'production', // Only send over HTTPS in production
        sameSite: 'strict' // Mitigates CSRF attacks
    };

    res.cookie('adminToken', token, cookieOptions);

    res.status(200).json({
        success: true,
        message: 'Login successful',
        data: {
            user: user.toJSON() // The token is NO LONGER sent in the body
        }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed',
      error: error.message
    });
  }
});

// Get current user profile (authenticated)
router.get('/profile', auth, (req, res) => {
  res.json({
    success: true,
    data: req.user.toJSON()
  });
});

// Update user profile (authenticated)
router.put('/profile', auth, async (req, res) => {
  try {
    const userId = req.user._id;
    const {
      firstName,
      lastName,
      phone,
      location,
    } = req.body;

    const updateData = {};
    if (firstName !== undefined) updateData.firstName = firstName;
    if (lastName !== undefined) updateData.lastName = lastName;
    if (phone !== undefined) updateData.phone = phone;
    if (location !== undefined) updateData.location = location;

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { $set: updateData },
      { new: true, runValidators: true }
    ).select('-password');

    if (!updatedUser) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({ success: true, data: updatedUser });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
