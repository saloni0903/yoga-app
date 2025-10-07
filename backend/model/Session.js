const mongoose = require('mongoose');
const crypto = require('crypto');

const sessionSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: () => crypto.randomUUID()
  },
  group_id: {
    type: String,
    ref: 'Group',
    required: true,
    index: true,
  },
  instructor_id: {
    type: String,
    ref: 'User',
    required: true,
    index: true,
  },
  session_date: {
    type: Date,
    required: true,
    index: true,
  },
  status: {
    type: String,
    enum: ['upcoming', 'completed', 'canceled'],
    default: 'upcoming',
  },
}, {
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  toJSON: {
    transform: function(doc, ret) {
      ret.id = ret._id;
      delete ret._id;
      delete ret.__v;
    }
  },
  toObject: { virtuals: true },
});

module.exports = mongoose.model('Session', sessionSchema);