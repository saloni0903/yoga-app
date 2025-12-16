// routes/health.js
const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth'); // Your JWT checker
const User = require('../model/User');
const HealthProfile = require('../model/HealthProfile');

// POST: Save the form data
router.post('/submit', auth, async (req, res) => {
  try {
    const { responses, totalScore } = req.body;

    // 1. Create the health profile entry
    const newProfile = new HealthProfile({
      user_id: req.user.id, // Gets ID from the token
      responses: responses,
      totalScore: totalScore
    });
    
    await newProfile.save();

    // 2. IMPORTANT: Mark the user as "Completed"
    await User.findByIdAndUpdate(req.user.id, { 
      isHealthProfileCompleted: true 
    });

    res.json({ success: true, message: 'Health Profile Saved!' });

  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server Error' });
  }
});

router.get('/', auth, async (req, res) => {
  try {
    // We populate user_id to show Name/Email instead of just an ID
    const profiles = await HealthProfile.find()
      .populate('user_id', 'firstName lastName email phone') 
      .sort({ date: -1 }); // Newest first

    res.json({ success: true, data: profiles });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server Error' });
  }
});

module.exports = router;