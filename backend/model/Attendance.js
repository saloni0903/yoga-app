const { DataTypes, Op } = require('sequelize');
const sequelize = require('../config/sequelize');

const Attendance = sequelize.define(
  'Attendance',
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    user_id: {
      type: DataTypes.UUID,
      allowNull: false,
    },
    group_id: {
      type: DataTypes.UUID,
      allowNull: false,
    },
    // Store the session date as a date-only value to simplify uniqueness per day.
    session_date: {
      type: DataTypes.DATEONLY,
      allowNull: false,
    },
    marked_at: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
    },
    qr_code_id: {
      type: DataTypes.UUID,
      allowNull: true,
    },
    attendance_type: {
      type: DataTypes.ENUM('present', 'late', 'early_leave', 'absent'),
      allowNull: false,
      defaultValue: 'present',
    },
    check_in_time: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
    },
    check_out_time: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    session_duration: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 60,
    },
    notes: {
      type: DataTypes.STRING(500),
      allowNull: true,
    },
    instructor_notes: {
      type: DataTypes.STRING(500),
      allowNull: true,
    },
    rating: {
      type: DataTypes.INTEGER,
      allowNull: true,
      validate: { min: 1, max: 5 },
    },
    feedback: {
      type: DataTypes.STRING(1000),
      allowNull: true,
    },
    location_verified: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    gps_coordinates: {
      type: DataTypes.JSONB,
      allowNull: true,
    },
    device_info: {
      type: DataTypes.JSONB,
      allowNull: true,
    },
    actual_duration: {
      type: DataTypes.VIRTUAL,
      get() {
        const checkIn = this.check_in_time ? new Date(this.check_in_time) : null;
        const checkOut = this.check_out_time ? new Date(this.check_out_time) : null;
        if (checkIn && checkOut) {
          const diffTime = Math.abs(checkOut - checkIn);
          return Math.round(diffTime / (1000 * 60));
        }
        return this.session_duration;
      },
    },
    is_present: {
      type: DataTypes.VIRTUAL,
      get() {
        return this.attendance_type === 'present' || this.attendance_type === 'late';
      },
    },
  },
  {
    tableName: 'attendance',
    timestamps: true,
    indexes: [
      { unique: true, fields: ['user_id', 'group_id', 'session_date'] },
      { fields: ['group_id', 'session_date'] },
      { fields: ['user_id', 'session_date'] },
      { fields: ['marked_at'] },
      { fields: ['qr_code_id'] },
    ],
    hooks: {
      beforeSave(attendance) {
        if (
          attendance.changed('attendance_type') &&
          attendance.attendance_type === 'early_leave' &&
          !attendance.check_out_time
        ) {
          attendance.check_out_time = new Date();
        }
      },
    },
  }
);

Attendance.prototype.toJSON = function toJSON() {
  const values = { ...this.get() };
  values._id = values.id;
  return values;
};

Attendance.getSessionAttendance = async function getSessionAttendance(groupId, sessionDate) {
  const User = sequelize.models.User;
  return Attendance.findAll({
    where: { group_id: groupId, session_date: sessionDate },
    include: [
      {
        model: User,
        as: 'user',
        attributes: ['id', 'firstName', 'lastName', 'email'],
      },
    ],
    order: [['marked_at', 'DESC']],
  });
};

Attendance.getUserAttendance = async function getUserAttendance(userId, groupId = null) {
  const Group = sequelize.models.Group;
  const where = { user_id: userId };
  if (groupId) where.group_id = groupId;

  return Attendance.findAll({
    where,
    include: [
      {
        model: Group,
        as: 'group',
        attributes: ['id', 'group_name', 'location_address', 'groupType'],
      },
    ],
    order: [['session_date', 'DESC']],
  });
};

Attendance.getAttendanceStats = async function getAttendanceStats(groupId, startDate, endDate) {

  // Using raw SQL is the simplest way to match the old aggregation output.
  const replacements = {
    groupId,
    startDate: startDate || null,
    endDate: endDate || null,
  };

  const dateFilterSql =
    startDate && endDate ? 'AND a.session_date BETWEEN :startDate AND :endDate' : '';

  const [rows] = await sequelize.query(
    `
      SELECT
        a.user_id AS user_id,
        (u."firstName" || ' ' || u."lastName") AS user_name,
        COUNT(*)::int AS total_sessions,
        SUM(CASE WHEN a.attendance_type IN ('present','late') THEN 1 ELSE 0 END)::int AS present_sessions,
        ROUND(AVG(CASE WHEN a.attendance_type IN ('present','late') THEN 1 ELSE 0 END)::numeric, 2) AS attendance_rate
      FROM attendance a
      JOIN users u ON u.id = a.user_id
      WHERE a.group_id = :groupId
      ${dateFilterSql}
      GROUP BY a.user_id, u."firstName", u."lastName"
      ORDER BY present_sessions DESC, total_sessions DESC
    `,
    { replacements }
  );

  // Ensure users exist (join already ensures), but keep structure consistent.
  return rows;
};

module.exports = Attendance;
