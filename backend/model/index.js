const sequelize = require('../config/sequelize');

const User = require('./User');
const Group = require('./Group');
const GroupMember = require('./GroupMember');
const Attendance = require('./Attendance');
const SessionQRCode = require('./SessionQRCode');
const HealthProfile = require('./HealthProfile');
const ReminderLog = require('./ReminderLog');

// Associations
Group.belongsTo(User, { as: 'instructor', foreignKey: 'instructor_id' });
User.hasMany(Group, { as: 'instructedGroups', foreignKey: 'instructor_id' });

GroupMember.belongsTo(User, { as: 'user', foreignKey: 'user_id' });
GroupMember.belongsTo(Group, { as: 'group', foreignKey: 'group_id' });
User.hasMany(GroupMember, { as: 'memberships', foreignKey: 'user_id' });
Group.hasMany(GroupMember, { as: 'members', foreignKey: 'group_id' });

Attendance.belongsTo(User, { as: 'user', foreignKey: 'user_id' });
Attendance.belongsTo(Group, { as: 'group', foreignKey: 'group_id' });
Attendance.belongsTo(SessionQRCode, { as: 'qrCode', foreignKey: 'qr_code_id' });
User.hasMany(Attendance, { as: 'attendanceRecords', foreignKey: 'user_id' });
Group.hasMany(Attendance, { as: 'attendanceRecords', foreignKey: 'group_id' });
SessionQRCode.hasMany(Attendance, { as: 'attendanceRecords', foreignKey: 'qr_code_id' });

SessionQRCode.belongsTo(Group, { as: 'group', foreignKey: 'group_id' });
SessionQRCode.belongsTo(User, { as: 'creator', foreignKey: 'created_by' });
Group.hasMany(SessionQRCode, { as: 'qrCodes', foreignKey: 'group_id' });
User.hasMany(SessionQRCode, { as: 'createdQrCodes', foreignKey: 'created_by' });

HealthProfile.belongsTo(User, { as: 'user', foreignKey: 'user_id' });
User.hasMany(HealthProfile, { as: 'healthProfiles', foreignKey: 'user_id' });

ReminderLog.belongsTo(Group, { as: 'group', foreignKey: 'groupId' });
Group.hasMany(ReminderLog, { as: 'reminderLogs', foreignKey: 'groupId' });

module.exports = {
  sequelize,
  User,
  Group,
  GroupMember,
  Attendance,
  SessionQRCode,
  HealthProfile,
  ReminderLog,
};
