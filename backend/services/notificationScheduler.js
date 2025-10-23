// backend/services/notificationScheduler.js
const cron = require('node-cron');
const GroupMember = require('../model/GroupMember');
const User = require('../model/User');
const Attendance = require('../model/Attendance');

const initializeScheduler = () => {
  console.log('✅ Notification scheduler initialized.');
  cron.schedule('*/5 * * * *', async () => {
    // console.log('⏰ Running scheduled notification check...'); // Temporarily silence during debug
    const now = new Date();
    try {
      // await sendSessionReminders(now); // Keep commented out
      // await sendMissedSessionNotifications(now); // Keep commented out
    } catch (error) {
      // console.error('Error during scheduled task:', error); // Temporarily silence during debug
    }
  });
};

// GUTTED FUNCTION - LEAVE EMPTY OR WITH PLACEHOLDER LOG
async function sendSessionReminders(now) {
  // console.log('[TODO] sendSessionReminders needs re-implementation.');
}

// GUTTED FUNCTION - LEAVE EMPTY OR WITH PLACEHOLDER LOG
async function sendMissedSessionNotifications(now) {
  // console.log('[TODO] sendMissedSessionNotifications needs re-implementation.');
}

module.exports = initializeScheduler;


// secured for future ref
// backend/services/notificationScheduler.js
// const cron = require('node-cron');
// // const Session = require('../model/Session'); // Assuming you have this model
// const GroupMember = require('../model/GroupMember');
// const User = require('../model/User');
// const Attendance = require('../model/Attendance');

// // This function will be the main entry point for our scheduler
// const initializeScheduler = () => {
//   console.log('✅ Notification scheduler initialized.');

//   // Schedule a task to run every 5 minutes
//   cron.schedule('*/5 * * * *', async () => {
//     console.log('⏰ Running scheduled notification check...');
//     const now = new Date();

//     try {
//       await sendSessionReminders(now);
//       await sendMissedSessionNotifications(now);
//     } catch (error) {
//       console.error('Error during scheduled task:', error);
//     }
//   });
// };

// async function sendSessionReminders(now) {
//   // Find sessions starting in about an hour that haven't been reminded yet
//   const oneHourFromNow = new Date(now.getTime() + 60 * 60 * 1000);
//   const oneHourBuffer = new Date(now.getTime() + 65 * 60 * 1000); // 65 mins to catch edge cases

//   const upcomingSessions = await Session.find({
//     session_date: { $gte: oneHourFromNow, $lt: oneHourBuffer },
//     'reminders.oneHour': { $ne: true }, // Add this field to your Session model
//   });

//   for (const session of upcomingSessions) {
//     console.log(`Sending 1-hour reminder for session of group ${session.group_id}`);
    
//     // TODO: Get all members of the group
//     // TODO: Get instructor
//     // TODO: Loop through them and send a notification via FCM
//     // TODO: Mark the reminder as sent in the database
//     // await Session.updateOne({ _id: session._id }, { $set: { 'reminders.oneHour': true } });
//   }
// }

// async function sendMissedSessionNotifications(now) {
//   // Find sessions that ended 10-15 minutes ago
//   const tenMinutesAgo = new Date(now.getTime() - 10 * 60 * 1000);
//   const fifteenMinutesAgo = new Date(now.getTime() - 15 * 60 * 1000);

//   const endedSessions = await Session.find({
//     // You'll need to calculate session_end_time based on session_date and duration
//     // This is a placeholder for that logic
//     session_end_time: { $gte: fifteenMinutesAgo, $lt: tenMinutesAgo },
//     'reminders.missed': { $ne: true }, // Add this field to your Session model
//   });

//   for (const session of endedSessions) {
//     console.log(`Checking for missed attendance for session of group ${session.group_id}`);
    
//     // TODO: Get all expected members
//     // TODO: Get all who actually attended
//     // TODO: Find the difference (the absentees)
//     // TODO: For each absentee, find their next session
//     // TODO: Send them a notification via FCM
//     // TODO: Mark the missed session check as done
//     // await Session.updateOne({ _id: session._id }, { $set: { 'reminders.missed': true } });
//   }
// }

// module.exports = initializeScheduler;