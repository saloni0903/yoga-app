const mongoose = require('mongoose');

const groupMemberSchema = new mongoose.Schema({
  _id: {
    type: mongoose.Schema.Types.UUID,
    default: () => new mongoose.Types.UUID(),
  },
  user_id: {
    type: mongoose.Schema.Types.UUID,
    ref: 'User',
    required: true,
  },
  group_id: {
    type: mongoose.Schema.Types.UUID,
    ref: 'Group',
    required: true,
  },
  joined_at: {
    type: Date,
    default: Date.now,
  },
  status: {
    type: String,
    enum: ['active', 'inactive', 'suspended', 'left'],
    default: 'active',
  },
  role: {
    type: String,
    enum: ['member', 'assistant', 'moderator'],
    default: 'member',
  },
  payment_status: {
    type: String,
    enum: ['paid', 'pending', 'overdue', 'free'],
    default: 'pending',
  },
  last_payment_date: {
    type: Date,
  },
  next_payment_due: {
    type: Date,
  },
  notes: {
    type: String,
    maxlength: 500,
  },
  emergency_contact: {
    name: String,
    phone: String,
    relationship: String,
  },
  medical_notes: {
    type: String,
    maxlength: 1000,
  },
  attendance_count: {
    type: Number,
    default: 0,
    min: 0,
  },
  last_attended: {
    type: Date,
  },
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
});

// Compound index to ensure unique user-group combination
groupMemberSchema.index({ user_id: 1, group_id: 1 }, { unique: true });

// Index for efficient queries
groupMemberSchema.index({ group_id: 1, status: 1 });
groupMemberSchema.index({ user_id: 1, status: 1 });
groupMemberSchema.index({ joined_at: -1 });

// Virtual for membership duration
groupMemberSchema.virtual('membership_duration_days').get(function() {
  if (this.joined_at) {
    const now = new Date();
    const diffTime = Math.abs(now - this.joined_at);
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  }
  return 0;
});

// Pre-save middleware to update last_attended if status changes
groupMemberSchema.pre('save', function(next) {
  if (this.isModified('status') && this.status === 'active') {
    this.last_attended = new Date();
  }
  next();
});

// Static method to get active members of a group
groupMemberSchema.statics.getActiveMembers = function(groupId) {
  return this.find({ group_id: groupId, status: 'active' }).populate('user_id');
};

// Static method to get user's active groups
groupMemberSchema.statics.getUserGroups = function(userId) {
  return this.find({ user_id: userId, status: 'active' }).populate('group_id');
};

module.exports = mongoose.model('GroupMember', groupMemberSchema);
