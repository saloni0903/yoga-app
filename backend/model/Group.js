// backend/model/Group.js
const mongoose = require('mongoose');

const groupSchema = new mongoose.Schema({
  // _id: {
  //   type: mongoose.Schema.Types.UUID,
  //   default: () => new mongoose.Types.UUID(),
  // },
  _id: { type: String, default: () => crypto.randomUUID() },
  // instructor_id: {
  //   type: mongoose.Schema.Types.UUID,
  //   ref: 'User',
  //   required: true,
  // },
  instructor_id: { type: String, ref: 'User', required: true },
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
      default: 'Point',
    },
    coordinates: {
      type: [Number],
      required: true,
    },
  },
  location_text: {
    type: String,
    required: true,
    trim: true,
    maxlength: 500,
  },
  latitude: {
    type: Number,
    required: true,
    min: -90,
    max: 90,
  },
  longitude: {
    type: Number,
    required: true,
    min: -180,
    max: 180,
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
  session_duration: {
    type: Number, // in minutes
    default: 60,
    min: 15,
    max: 180,
  },
  price_per_session: {
    type: Number,
    default: 0,
    min: 0,
  },
  currency: {
    type: String,
    default: 'USD',
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
  created_at: {
    type: Date,
    default: Date.now,
  },
  updated_at: {
    type: Date,
    default: Date.now,
  },
  schedule: {
    type: {
      startTime: { type: String, required: true },
      endTime: { type: String, required: true },
      days: { 
        type: [String], 
        required: true, 
        enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'] 
      },
      startDate: { type: Date, required: true },
      endDate: { type: Date, required: true },
      recurrence: { type: String, default: 'NONE' }, // ✅ ADD THIS LINE
    },
    required: false,
  },
}, {
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
