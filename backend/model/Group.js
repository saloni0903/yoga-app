// backend/model/Group.js
const mongoose = require('mongoose');
const crypto = require('crypto');

const groupSchema = new mongoose.Schema({
  instructor_id: { 
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User', 
    required: true 
  },
  groupType: {
    type: String,
    enum: ['online', 'offline'],
    default: 'offline',
    required: true,
  }, 
  group_name: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100,
  },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      required: function() { return this.groupType === 'offline'; }
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      required: function() { return this.groupType === 'offline'; }
    },
    address: {
        type: String,
        required: function() { return this.groupType === 'offline'; }
    }
  },
  color: {
    type: String,
    default: '#2E7D6E', // Default to your primary app color
  },
  schedule: {
    type: {
      startTime: { type: String, required: true }, // e.g., "07:00"
      endTime: { type: String, required: true },   // e.g., "08:00"
      days: { 
        type: [String], 
        required: true, 
        enum: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'] 
      },
      startDate: { type: Date, required: true },
      endDate: { type: Date, required: true },
    },
    required: true,
  },
  is_active: {
    type: Boolean,
    default: true,
  },
  description: {
    type: String,
    trim: true,
    maxlength: 1000,
  },
  max_participants: {
    type: Number,
    default: 20,
    min: 1,
    max: 100,
  },
  yoga_style: {
    type: String,
    enum: ['hatha', 'vinyasa', 'ashtanga', 'iyengar', 'bikram', 'yin', 'restorative', 'power', 'other'],
    default: 'hatha',
  },
  difficulty_level: {
    type: String,
    enum: ['beginner', 'intermediate', 'advanced', 'all-levels'],
    default: 'all-levels',
  },
  // session_duration: {
  //   type: Number, // in minutes
  //   default: 60,
  //   min: 15,
  //   max: 180,
  // },
  price_per_session: {
    type: Number,
    default: 0,
    min: 0,
  },
  currency: {
    type: String,
    default: 'INR',
    maxlength: 3,
  },
  requirements: {
    type: [String],
    default: [],
  },
  equipment_needed: {
    type: [String],
    default: [],
  },
  meetLink: {
    type: String,
    trim: true,
  },
  created_at: {
    type: Date,
    default: Date.now,
  },
  updated_at: {
    type: Date,
    default: Date.now,
  },
 
}, 
{
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  toJSON: {
    virtuals: true,
    transform: function(doc, ret) {
      ret.id = ret._id.toString(); // Create 'id' as a string
      delete ret.__v; // Remove the version key
    }
  },
  toObject: { virtuals: true },
});

// Virtual for location coordinates
groupSchema.virtual('coordinates').get(function () {
  return {
    latitude: this.latitude,
    longitude: this.longitude,
  };
});

groupSchema.virtual('location_text').get(function () {
  if (this.groupType === 'offline' && this.location) {
    return this.location.address;
  }
  return null; // Online groups do not have a location.address
});

// Index for geospatial queries
groupSchema.index({ location: '2dsphere' });
// groupSchema.index({ latitude: 1, longitude: 1 });
groupSchema.index({ instructor_id: 1 });
groupSchema.index({ is_active: 1 });
groupSchema.index({ created_at: -1 });

// Pre-save middleware to update updated_at
groupSchema.pre('save', function (next) {
  this.updated_at = new Date();
  next();
});

module.exports = mongoose.model('Group', groupSchema);
