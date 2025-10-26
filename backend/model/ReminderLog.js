// backend/model/ReminderLog.js
const mongoose = require('mongoose');

const reminderLogSchema = new mongoose.Schema({
    groupId: {
        type: mongoose.Schema.Types.ObjectId, // Use ObjectId if your Group _id is ObjectId
        ref: 'Group', // Reference the Group model
        required: true
    },
    sessionDateISO: { // Store the calculated session start time as an ISO string
        type: String,
        required: true
    },
    reminderType: { // Type of reminder sent ('1hr' or '24hr')
        type: String,
        enum: ['1hr', '24hr'],
        required: true
    }
}, {
    timestamps: true // Adds createdAt and updatedAt automatically
});

// Create a compound index to ensure we don't log the same reminder twice
// and to make lookups faster.
reminderLogSchema.index({ groupId: 1, sessionDateISO: 1, reminderType: 1 }, { unique: true });

module.exports = mongoose.model('ReminderLog', reminderLogSchema);