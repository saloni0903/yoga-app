// backend/model/SessionQRCode.js
const mongoose = require('mongoose');
const crypto = require('crypto');

const sessionQRCodeSchema = new mongoose.Schema({
  _id: {
    type: mongoose.Schema.Types.UUID,
    default: () => new mongoose.Types.UUID(),
  },
  group_id: {
    type: mongoose.Schema.Types.UUID,
    ref: 'Group',
    required: true,
  },
  token: {
    type: String,
    required: true,
    unique: true,
    index: true,
  },
  session_date: {
    type: Date,
    required: true,
  },
  expires_at: {
    type: Date,
    required: true,
  },
  created_at: {
    type: Date,
    default: Date.now,
  },
  created_by: {
    type: mongoose.Schema.Types.UUID,
    ref: 'User',
    required: true,
  },
  is_active: {
    type: Boolean,
    default: true,
  },
  usage_count: {
    type: Number,
    default: 0,
    min: 0,
  },
  max_usage: {
    type: Number,
    default: 100,
    min: 1,
  },
  session_start_time: {
    type: Date,
  },
  session_end_time: {
    type: Date,
  },
  location_restriction: {
    enabled: {
      type: Boolean,
      default: false,
    },
    latitude: Number,
    longitude: Number,
    radius: Number, // in meters
  },
  qr_data: {
    type: String, // The actual QR code data/URL
  },
  metadata: {
    session_type: {
      type: String,
      enum: ['regular', 'special', 'workshop', 'retreat'],
      default: 'regular',
    },
    description: String,
    special_instructions: String,
  },
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
});

// Index for efficient queries
sessionQRCodeSchema.index({ group_id: 1, session_date: 1 });
sessionQRCodeSchema.index({ token: 1 });
sessionQRCodeSchema.index({ expires_at: 1 });
sessionQRCodeSchema.index({ is_active: 1 });
sessionQRCodeSchema.index({ created_at: -1 });

// Virtual for QR code validity
sessionQRCodeSchema.virtual('is_valid').get(function() {
  const now = new Date();
  return this.is_active && 
         this.expires_at > now && 
         this.usage_count < this.max_usage;
});

// Virtual for time until expiration
sessionQRCodeSchema.virtual('time_until_expiry').get(function() {
  const now = new Date();
  const diffTime = this.expires_at - now;
  return Math.max(0, diffTime);
});

// Pre-save middleware to generate token if not provided
sessionQRCodeSchema.pre('save', function(next) {
  if (!this.token) {
    this.token = crypto.randomBytes(32).toString('hex');
  }
  
  // Generate QR data URL if not provided
  if (!this.qr_data) {
    this.qr_data = `${process.env.APP_URL || 'http://localhost:3000'}/qr/scan/${this.token}`;
  }
  
  next();
});

// Static method to generate QR code for a session
sessionQRCodeSchema.statics.generateForSession = async function(groupId, sessionDate, createdBy, options = {}) {
  const sessionStartTime = options.sessionStartTime || new Date(sessionDate);
  const sessionEndTime = options.sessionEndTime || new Date(sessionStartTime.getTime() + (60 * 60 * 1000)); // 1 hour default
  const expiresAt = options.expiresAt || new Date(sessionEndTime.getTime() + (30 * 60 * 1000)); // 30 minutes after session end
  
  const qrCode = new this({
    group_id: groupId,
    session_date: sessionDate,
    expires_at: expiresAt,
    created_by: createdBy,
    session_start_time: sessionStartTime,
    session_end_time: sessionEndTime,
    max_usage: options.maxUsage || 100,
    location_restriction: options.locationRestriction || { enabled: false },
    metadata: options.metadata || {},
  });
  
  return await qrCode.save();
};

// Static method to validate and use QR code
sessionQRCodeSchema.statics.validateAndUse = async function(token, userId, location = null) {
  const qrCode = await this.findOne({ token, is_active: true });
  
  if (!qrCode) {
    throw new Error('Invalid QR code');
  }
  
  if (!qrCode.is_valid) {
    throw new Error('QR code has expired or reached usage limit');
  }
  
  // Check location restriction if enabled
  if (qrCode.location_restriction.enabled && location) {
    const distance = calculateDistance(
      location.latitude,
      location.longitude,
      qrCode.location_restriction.latitude,
      qrCode.location_restriction.longitude
    );
    
    if (distance > qrCode.location_restriction.radius) {
      throw new Error('You are too far from the session location');
    }
  }
  
  // Increment usage count
  qrCode.usage_count += 1;
  await qrCode.save();
  
  return qrCode;
};

// Static method to get active QR codes for a group
sessionQRCodeSchema.statics.getActiveForGroup = function(groupId, sessionDate = null) {
  const query = { group_id: groupId, is_active: true };
  
  if (sessionDate) {
    query.session_date = sessionDate;
  } else {
    // Get QR codes for today and future sessions
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    query.session_date = { $gte: today };
  }
  
  return this.find(query).sort({ session_date: 1, created_at: -1 });
};

// Helper function to calculate distance between two coordinates
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Earth's radius in meters
  const φ1 = lat1 * Math.PI / 180;
  const φ2 = lat2 * Math.PI / 180;
  const Δφ = (lat2 - lat1) * Math.PI / 180;
  const Δλ = (lon2 - lon1) * Math.PI / 180;

  const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
            Math.cos(φ1) * Math.cos(φ2) *
            Math.sin(Δλ/2) * Math.sin(Δλ/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

  return R * c; // Distance in meters
}

module.exports = mongoose.model('SessionQRCode', sessionQRCodeSchema);
