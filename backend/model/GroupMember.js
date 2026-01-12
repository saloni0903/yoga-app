const { DataTypes } = require('sequelize');
const sequelize = require('../config/sequelize');

const GroupMember = sequelize.define(
  'GroupMember',
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
    joined_at: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
    },
    status: {
      type: DataTypes.ENUM('active', 'inactive', 'suspended', 'left'),
      allowNull: false,
      defaultValue: 'active',
    },
    role: {
      type: DataTypes.ENUM('member', 'assistant', 'moderator'),
      allowNull: false,
      defaultValue: 'member',
    },
    payment_status: {
      type: DataTypes.ENUM('paid', 'pending', 'overdue', 'free'),
      allowNull: false,
      defaultValue: 'pending',
    },
    last_payment_date: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    next_payment_due: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    notes: {
      type: DataTypes.STRING(500),
      allowNull: true,
    },
    emergency_contact: {
      type: DataTypes.JSONB,
      allowNull: true,
    },
    medical_notes: {
      type: DataTypes.STRING(1000),
      allowNull: true,
    },
    attendance_count: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    last_attended: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    membership_duration_days: {
      type: DataTypes.VIRTUAL,
      get() {
        if (!this.joined_at) return 0;
        const now = new Date();
        const diffTime = Math.abs(now - new Date(this.joined_at));
        return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
      },
    },
  },
  {
    tableName: 'group_members',
    timestamps: true,
    indexes: [
      { unique: true, fields: ['user_id', 'group_id'] },
      { fields: ['group_id', 'status'] },
      { fields: ['user_id', 'status'] },
      { fields: ['joined_at'] },
    ],
    hooks: {
      beforeSave(membership) {
        if (membership.changed('status') && membership.status === 'active') {
          membership.last_attended = new Date();
        }
      },
    },
  }
);

GroupMember.prototype.toJSON = function toJSON() {
  const values = { ...this.get() };
  values._id = values.id;
  return values;
};

module.exports = GroupMember;
