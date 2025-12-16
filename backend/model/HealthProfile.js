
// model/HealthProfile.js
const mongoose = require('mongoose');

const HealthProfileSchema = new mongoose.Schema({
  user_id: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  // Store answers simply. We can expand this later if Ayush Dept asks.
  responses: {
    sugar: String,
    snacking: String,
    lateDinner: String,
    physicalActivity: String,
    screenTime: String,
    socialMedia: String,
    music: String,
    sleep: String,
    alcohol: String,
    smoking: String,
    tobacco: String
  },
  totalScore: Number,
  date: { type: Date, default: Date.now }
});

module.exports = mongoose.model('HealthProfile', HealthProfileSchema);