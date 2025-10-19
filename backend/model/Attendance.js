// backend/model/Attendance.js
const mongoose = require('mongoose');
const crypto = require('crypto');

const attendanceSchema = new mongoose.Schema({
  user_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  group_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Group',
    required: true,
  },
  session_date: {
    type: Date,
    required: true,
  },
  marked_at: {
    type: Date,
    default: Date.now,
  },
  qr_code_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'SessionQRCode',
  },
  attendance_type: {
    type: String,
    enum: ['present', 'late', 'early_leave', 'absent'],
    default: 'present',
  },
  check_in_time: {
    type: Date,
    default: Date.now,
  },
  check_out_time: {
    type: Date,
  },
  session_duration: {
    type: Number, // in minutes
    default: 60,
  },
  notes: {
    type: String,
    maxlength: 500,
  },
  instructor_notes: {
    type: String,
    maxlength: 500,
  },
  rating: {
    type: Number,
    min: 1,
    max: 5,
  },
  feedback: {
    type: String,
    maxlength: 1000,
  },
  location_verified: {
    type: Boolean,
    default: false,
  },
  gps_coordinates: {
    latitude: Number,
    longitude: Number,
  },
  device_info: {
    user_agent: String,
    ip_address: String,
  },
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
});

// Compound index to ensure unique attendance per user per session
attendanceSchema.index({ user_id: 1, group_id: 1, session_date: 1 }, { unique: true });

// Index for efficient queries
attendanceSchema.index({ group_id: 1, session_date: 1 });
attendanceSchema.index({ user_id: 1, session_date: 1 });
attendanceSchema.index({ marked_at: -1 });
attendanceSchema.index({ qr_code_id: 1 });

// Virtual for session duration
attendanceSchema.virtual('actual_duration').get(function() {
  if (this.check_in_time && this.check_out_time) {
    const diffTime = Math.abs(this.check_out_time - this.check_in_time);
    return Math.round(diffTime / (1000 * 60)); // Convert to minutes
  }
  return this.session_duration;
});

// Virtual for attendance status
attendanceSchema.virtual('is_present').get(function() {
  return this.attendance_type === 'present' || this.attendance_type === 'late';
});

// Pre-save middleware to set check_out_time if not provided
attendanceSchema.pre('save', function(next) {
  if (this.isModified('attendance_type') && this.attendance_type === 'early_leave' && !this.check_out_time) {
    this.check_out_time = new Date();
  }
  next();
});

// Static method to get attendance for a specific session
attendanceSchema.statics.getSessionAttendance = function(groupId, sessionDate) {
  return this.find({ 
    group_id: groupId, 
    session_date: sessionDate 
  }).populate('user_id', 'firstName lastName email');
};

// Static method to get user's attendance history
attendanceSchema.statics.getUserAttendance = function(userId, groupId = null) {
  const query = { user_id: userId };
  if (groupId) {
    query.group_id = groupId;
  }
  return this.find(query).populate('group_id', 'group_name location_text');
};

// Static method to get attendance statistics
attendanceSchema.statics.getAttendanceStats = function(groupId, startDate, endDate) {
  // const matchStage = {
  //   group_id: new mongoose.Types.UUID(groupId)
  // };
  const matchStage = { group_id: groupId }

  
  if (startDate && endDate) {
    matchStage.session_date = {
      $gte: startDate,
      $lte: endDate
    };
  }

  return this.aggregate([
    { $match: matchStage },
    {
      $group: {
        _id: '$user_id',
        total_sessions: { $sum: 1 },
        present_sessions: {
          $sum: {
            $cond: [
              { $in: ['$attendance_type', ['present', 'late']] },
              1,
              0
            ]
          }
        },
        attendance_rate: {
          $avg: {
            $cond: [
              { $in: ['$attendance_type', ['present', 'late']] },
              1,
              0
            ]
          }
        }
      }
    },
    {
      $lookup: {
        from: 'users',
        localField: '_id',
        foreignField: '_id',
        as: 'user'
      }
    },
    {
      $unwind: '$user'
    },
    {
      $project: {
        user_id: '$_id',
        user_name: { $concat: ['$user.firstName', ' ', '$user.lastName'] },
        total_sessions: 1,
        present_sessions: 1,
        attendance_rate: { $round: ['$attendance_rate', 2] }
      }
    }
  ]);
};

module.exports = mongoose.model('Attendance', attendanceSchema);
