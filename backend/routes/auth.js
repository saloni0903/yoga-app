// backend/routes/auth.js
const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../model/User');
const auth = require('../middleware/auth');  
const crypto = require('crypto');
const { sendEmail } = require('../services/emailService');
const { Op } = require('sequelize');
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
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with this email'
      });
    }

    // Create new user with all fields from Flutter
    const user = await User.create({
      email,
      password,
      firstName,
      lastName,
      role,
      location,
      phone,
      samagraId,
    });

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
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
    const user = await User.findOne({ where: { email: String(email || '').toLowerCase().trim() } });
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
      { userId: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '7d' }
    );
    
    const cookieOptions = {
    httpOnly: true, // Makes the cookie inaccessible to client-side JavaScript
    secure: process.env.NODE_ENV === 'production', // Use secure cookies in production (HTTPS)
    maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days (same as JWT expiry)
    sameSite: process.env.NODE_ENV === 'production' ? 'None' : 'lax', // Optional: Helps prevent CSRF attacks
  };

    if (user.role === 'admin') {
      // For Admin Dashboard (Web): Use cookie, don't send token in body
      res.cookie('adminToken', token, cookieOptions);
      res.status(200).json({
          success: true,
          message: 'Login successful',
          data: {
              user: user.toJSON()
          }
      });
    } else {
      // For Participant/Instructor (Mobile): Send token in JSON body
      res.status(200).json({
          success: true,
          message: 'Login successful',
          data: {
              user: user.toJSON(),
              token: token // <--- THIS IS WHAT THE MOBILE APP NEEDS
          }
      });
    }

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed',
      error: error.message
    });
  }
});

// Step 1: User requests an OTP
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;

  try {
    const user = await User.findOne({ where: { email: String(email || '').toLowerCase().trim() } });

    // Security Best Practice:
    // Always send a generic success response, even if the user isn't found.
    // This prevents attackers from checking which emails are registered.
    if (!user) {
      return res.status(200).json({
        success: true,
        message: 'If an account with this email exists, a password reset OTP has been sent.',
      });
    }

    // Generate a 6-digit OTP
    const otp = crypto.randomInt(100000, 999999).toString();
    // Set an expiration time (e.g., 10 minutes from now)
    const expires = Date.now() + 10 * 60 * 1000; // 10 minutes

    // Save the OTP and expiry to the user document
    user.resetPasswordOtp = otp;
    user.resetPasswordExpires = new Date(expires);
    await user.save();

    // Send the email
    const subject = 'Your Password Reset OTP';
    const text = `You are receiving this email because you (or someone else) requested a password reset for your account.\n\nYour OTP is: ${otp}\n\nThis OTP is valid for 10 minutes.\n\nIf you did not request this, please ignore this email.\n`;
    const html = `<p>You are receiving this email because you (or someone else) requested a password reset for your account.</p>
                  <p>Your OTP is: <strong>${otp}</strong></p>
                  <p>This OTP is valid for 10 minutes.</p>
                  <p>If you did not request this, please ignore this email.</p>`;

    await sendEmail({ to: user.email, subject, text, html });

    res.status(200).json({
      success: true,
      message: 'If an account with this email exists, a password reset OTP has been sent.',
    });
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while trying to send the reset OTP.',
      error: error.message,
    });
  }
});

// Step 2: User sends email, OTP, and new password
router.post('/reset-password', async (req, res) => {
  const { email, otp, password } = req.body;

  if (!email || !otp || !password) {
    return res.status(400).json({ success: false, message: 'Email, OTP, and new password are required.' });
  }

  try {
    // Find the user based on email, matching OTP, and unexpired time
    const user = await User.findOne({
      where: {
        email: String(email || '').toLowerCase().trim(),
        resetPasswordOtp: otp,
        resetPasswordExpires: { [Op.gt]: new Date() },
      },
    });

    // If no user matches, the OTP is invalid or expired
    if (!user) {
      return res.status(400).json({ success: false, message: 'Invalid or expired OTP. Please try again.' });
    }

    // Set the new password. The 'pre-save' hook in User.js will hash it.
    user.password = password;
    // Clear the OTP fields so it can't be used again
    user.resetPasswordOtp = null;
    user.resetPasswordExpires = null;

    await user.save();

    res.status(200).json({
      success: true,
      message: 'Password has been reset successfully. You can now log in.',
    });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred while resetting the password.',
      error: error.message,
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
    const userId = req.user.id;
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

    await User.update(updateData, { where: { id: userId } });
    const updatedUser = await User.findByPk(userId);

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
