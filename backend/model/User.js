// backend/model/User.js
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

const userSchema = new mongoose.Schema({
  _id: { 
    type: String, 
    default: () => crypto.randomUUID() 
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
  },
  password: {
    type: String,
    required: true,
    minlength: 8,
  },
  firstName: {
    type: String,
    required: true,
    trim: true,
  },
  lastName: {
    type: String,
    required: true,
    trim: true,
  },
  phone: {
    type: String,
    trim: true,
  },
  samagraId: {
    type: String,
    trim: true,
  },
  role: {
    type: String,
    enum: ['instructor', 'participant','admin'],
    default: 'participant',
  },
  location: {
    type: String,
    required: true,
    trim: true,
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  profileImage: {
    type: String,
    default: null,
  },
  dateOfBirth: {
    type: Date,
  },
  emergencyContact: {
    name: String,
    phone: String,
    relationship: String,
  },
  medicalInfo: {
    allergies: [String],
    conditions: [String],
    medications: [String],
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'suspended'],
    default: 'approved', // Default to approved for participants and admins
  },
  preferences: {
    notifications: {
      email: { type: Boolean, default: true },
      sms: { type: Boolean, default: false },
      push: { type: Boolean, default: true },
    },
    yogaLevel: {
      type: String,
      enum: ['beginner', 'intermediate', 'advanced'],
      default: 'beginner',
    },
  },
}, {
  timestamps: true,
  toJSON: {
    virtuals: true,
    transform: function (doc, ret) {
      // ret.id = ret._id.toString();
      delete ret.__v;
      delete ret.password;
    }
  }
});

userSchema.virtual('fullName').get(function() { return `${this.firstName} ${this.lastName}`; });
userSchema.pre('save', async function(next) { 
    if (this.isModified('password')) { 
      const salt = await bcrypt.genSalt(12); 
      this.password = await bcrypt.hash(this.password, salt); 
    } 
    if (this.isNew && this.role === 'instructor') {
      this.status = 'pending';
    }
    next(); 
  }
);
userSchema.methods.comparePassword = async function(candidatePassword) { return bcrypt.compare(candidatePassword, this.password); };

module.exports = mongoose.model('User', userSchema);