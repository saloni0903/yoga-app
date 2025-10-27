// backend/services/notificationService.js
const cron = require('node-cron');
const User = require('../model/User');
const Group = require('../model/Group');
const GroupMember = require('../model/GroupMember'); // <-- Add GroupMember require
const ReminderLog = require('../model/ReminderLog'); // <-- Add ReminderLog require
const admin = require('../config/firebase');

// --- Helper: Calculate Session Occurrences ---
// Calculates session dates within a given window based on group schedule
function calculateSessionsForGroup(group, windowStart, windowEnd) {
    const sessionsInWindow = [];
    if (!group.schedule || !group.schedule.startDate || !group.schedule.endDate || !group.schedule.days || !group.schedule.startTime) {
        // console.warn(`Group ${group._id} has incomplete schedule, skipping reminder calculation.`);
        return sessionsInWindow; // Skip groups with incomplete schedules
    }

    const { startDate, endDate, days, startTime } = group.schedule;
    const groupStartDate = new Date(startDate);
    const groupEndDate = new Date(endDate);

    // Ensure the group's schedule overlaps with the reminder window at all
    if (groupEndDate < windowStart || groupStartDate > windowEnd) {
        return sessionsInWindow;
    }

    const dayNameToNum = { 'Sunday': 0, 'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4, 'Friday': 5, 'Saturday': 6 };
    const scheduledDays = days.map(d => dayNameToNum[d]).filter(d => d !== undefined); // Filter out invalid day names

    if (scheduledDays.length === 0) {
        // console.warn(`Group ${group._id} has invalid days in schedule: ${days}`);
        return sessionsInWindow; // Skip if days array is invalid
    }

    // Determine the actual start date for iteration (latest of group start or window start)
    let currentDate = new Date(Math.max(groupStartDate.getTime(), windowStart.getTime()));
    // Adjust currentDate to the beginning of its day to avoid time zone issues with date comparison
    currentDate.setHours(0, 0, 0, 0);

    // Determine the actual end date for iteration (earliest of group end or window end)
    const iterationEndDate = new Date(Math.min(groupEndDate.getTime(), windowEnd.getTime()));
    iterationEndDate.setHours(23, 59, 59, 999); // Ensure we include the whole end day

    const [startHour, startMinute] = startTime.split(':').map(Number);
    if (isNaN(startHour) || isNaN(startMinute)) {
       console.error(`Group ${group._id} has invalid startTime format: ${startTime}`);
       return sessionsInWindow; // Skip if time format is wrong
    }

    // Iterate day by day within the relevant window
    while (currentDate <= iterationEndDate) {
        if (scheduledDays.includes(currentDate.getDay())) {
            // Create the potential session date/time
            const sessionDateTime = new Date(currentDate);
            sessionDateTime.setHours(startHour, startMinute, 0, 0);

            // Check if this specific session time falls EXACTLY within our target window
            if (sessionDateTime >= windowStart && sessionDateTime < windowEnd) {
                sessionsInWindow.push(sessionDateTime);
            }
        }
        // Move to the next day
        currentDate.setDate(currentDate.getDate() + 1);
    }

    return sessionsInWindow;
}


// --- Main Reminder Processing Function ---
async function processReminders(now) {
    // console.log(`[${now.toISOString()}] Running processReminders...`); // Debug log

    // Define time windows (relative to 'now')
    const reminderCheckIntervalMinutes = 15; // Should match or be smaller than cron interval

    // --- 1-Hour Window ---
    const oneHourAheadStart = new Date(now.getTime() + 60 * 60 * 1000); // Exactly 60 mins from now
    const oneHourAheadEnd = new Date(oneHourAheadStart.getTime() + reminderCheckIntervalMinutes * 60 * 1000); // 60 to (60 + interval) mins

    // --- 24-Hour Window ---
    const twentyFourHoursAheadStart = new Date(now.getTime() + 24 * 60 * 60 * 1000); // Exactly 24h from now
    const twentyFourHoursAheadEnd = new Date(twentyFourHoursAheadStart.getTime() + reminderCheckIntervalMinutes * 60 * 1000); // 24h to (24h + interval)

    // Find groups whose schedules *might* overlap with our widest window
    const earliestWindowStart = oneHourAheadStart;
    const latestWindowEnd = twentyFourHoursAheadEnd;

    try {
        const activeGroups = await Group.find({
            'schedule.endDate': { $gte: earliestWindowStart }, // Only groups whose schedule hasn't ended before the earliest reminder time
             // Add other filters if needed, e.g., only active groups?
        }).lean(); // Use .lean() for performance when just reading data

        // console.log(`Found ${activeGroups.length} potentially active groups.`); // Debug log

        for (const group of activeGroups) {
            // Calculate sessions for this group within both windows
            const sessionsFor1Hour = calculateSessionsForGroup(group, oneHourAheadStart, oneHourAheadEnd);
            const sessionsFor24Hours = calculateSessionsForGroup(group, twentyFourHoursAheadStart, twentyFourHoursAheadEnd);

            if (sessionsFor1Hour.length === 0 && sessionsFor24Hours.length === 0) {
                continue; // Skip group if no sessions fall in either window
            }

            // --- Process 1-Hour Reminders ---
            for (const sessionDate of sessionsFor1Hour) {
                const sessionDateISO = sessionDate.toISOString();
                const reminderType = '1hr';

                // Check if reminder was already sent
                const existingLog = await ReminderLog.findOne({
                    groupId: group._id,
                    sessionDateISO: sessionDateISO,
                    reminderType: reminderType
                }).lean();

                if (!existingLog) {
                    // Reminder not sent, find members and send
                    const members = await GroupMember.find({ group_id: group._id, status: 'active' }).select('user_id').lean(); // Find active members
                    if (members.length > 0) {
                        console.log(`[Reminder] Sending 1hr reminder for group "${group.group_name}" session at ${sessionDateISO} to ${members.length} members.`);
                        for (const member of members) {
                            await sendNotificationToUser(
                                member.user_id.toString(), // Ensure it's a string ID
                                'Session Reminder',
                                `Your yoga session for "${group.group_name}" starts in about 1 hour.`,
                                { type: 'session_reminder', groupId: group._id.toString(), sessionDate: sessionDateISO }
                            );
                        }
                        // Log that reminder was sent
                        await ReminderLog.create({
                            groupId: group._id,
                            sessionDateISO: sessionDateISO,
                            reminderType: reminderType
                        });
                    }
                }
            }

            // --- Process 24-Hour Reminders ---
            for (const sessionDate of sessionsFor24Hours) {
                const sessionDateISO = sessionDate.toISOString();
                const reminderType = '24hr';

                // Check if reminder was already sent
                const existingLog = await ReminderLog.findOne({
                    groupId: group._id,
                    sessionDateISO: sessionDateISO,
                    reminderType: reminderType
                }).lean();

                 if (!existingLog) {
                    // Reminder not sent, find members and send
                    const members = await GroupMember.find({ group_id: group._id, status: 'active' }).select('user_id').lean();
                     if (members.length > 0) {
                        console.log(`[Reminder] Sending 24hr reminder for group "${group.group_name}" session at ${sessionDateISO} to ${members.length} members.`);
                        for (const member of members) {
                             await sendNotificationToUser(
                                member.user_id.toString(),
                                'Upcoming Session',
                                `Reminder: Your yoga session for "${group.group_name}" is tomorrow.`,
                                { type: 'session_reminder', groupId: group._id.toString(), sessionDate: sessionDateISO }
                            );
                        }
                        // Log that reminder was sent
                        await ReminderLog.create({
                            groupId: group._id,
                            sessionDateISO: sessionDateISO,
                            reminderType: reminderType
                        });
                    }
                }
            }
        } // End loop through groups

    } catch (error) {
        console.error('[Reminder] Error during processReminders:', error);
    }
}


// --- Initialize Scheduler ---
const initializeScheduler = () => {
  console.log('✅ Notification scheduler initialized.');
  // Schedule processReminders to run periodically
  cron.schedule('*/15 * * * *', async () => { // Run every 15 minutes
    const now = new Date();
    await processReminders(now);
  });
};

// --- Notification Sending Logic (Keep as is) ---
async function sendNotificationToUser(userId, title, body, data = {}) {
    // ... (Keep the exact code from the previous response for this function) ...
     // Ensure userId is a valid string before proceeding
  if (typeof userId !== 'string' || !userId) {
     console.error('Invalid userId provided for notification:', userId);
     return;
  }

  try {
    // Use findById which works with Mongoose default _id (ObjectId or String depending on schema)
    const user = await User.findById(userId);
    if (!user) {
      // console.log(`User ${userId} not found for notification.`); // Can be noisy
      return;
    }
    if (!user.fcmTokens || user.fcmTokens.length === 0) {
      // console.log(`User ${user.email} (${userId}) has no FCM tokens.`); // Can be noisy
      return;
    }

    const message = {
      notification: { title, body },
      tokens: user.fcmTokens, // Send to all registered devices for the user
      data: data // Optional data payload for the app (e.g., { type: 'new_member', groupId: '...' })
    };

    // const response = await admin.messaging().sendMulticast(message);
    const response = await admin.messaging().sendEachForMulticast(message); // MUST BE sendEachForMulticast

    // --- Handle potential failures and cleanup invalid tokens ---
    if (response.failureCount > 0) {
        console.warn(`[FCM] Failed to send notification to ${response.failureCount} tokens for user ${userId}.`);
        const tokensToRemove = [];
        response.responses.forEach((resp, idx) => {
            if (!resp.success) {
                const errorCode = resp.error?.code;
                // These errors indicate the token is permanently invalid
                if (errorCode === 'messaging/registration-token-not-registered' ||
                    errorCode === 'messaging/invalid-registration-token') {
                    tokensToRemove.push(user.fcmTokens[idx]);
                } else {
                     console.error(`[FCM] Send error for token ${user.fcmTokens[idx].substring(0,10)}...:`, resp.error?.message || resp.error);
                }
            }
        });
        // If invalid tokens were found, remove them from the user's document
        if (tokensToRemove.length > 0) {
            await User.updateOne({ _id: userId }, { $pullAll: { fcmTokens: tokensToRemove } });
            console.log(`[FCM] Removed ${tokensToRemove.length} invalid tokens for user ${userId}.`)
        }
    }
    // --- End Failure Handling ---

  } catch (error) {
     // Catch errors during DB lookup or sending
     if (error.kind === 'ObjectId' || error.name === 'CastError') {
         console.error(`[Notification] Invalid user ID format: ${userId}`);
     } else {
        console.error(`[Notification] Error sending notification to user ${userId}:`, error);
     }
  }
}

// --- Export ---
module.exports = {
    initializeScheduler,
    sendNotificationToUser
};