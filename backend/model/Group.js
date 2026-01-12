const { DataTypes } = require('sequelize');
const sequelize = require('../config/sequelize');

const Group = sequelize.define(
  'Group',
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    instructor_id: {
      type: DataTypes.UUID,
      allowNull: false,
    },
    groupType: {
      type: DataTypes.ENUM('online', 'offline'),
      allowNull: false,
      defaultValue: 'offline',
    },
    group_name: {
      type: DataTypes.STRING(100),
      allowNull: false,
    },
    // Keep a structured location, but also store the address separately for easy searching.
    location: {
      type: DataTypes.JSONB,
      allowNull: true,
    },
    location_address: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    latitude: {
      type: DataTypes.DOUBLE,
      allowNull: true,
    },
    longitude: {
      type: DataTypes.DOUBLE,
      allowNull: true,
    },
    color: {
      type: DataTypes.STRING,
      allowNull: false,
      defaultValue: '#2E7D6E',
    },
    schedule: {
      type: DataTypes.JSONB,
      allowNull: false,
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
    },
    description: {
      type: DataTypes.STRING(1000),
      allowNull: true,
    },
    max_participants: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 20,
    },
    yoga_style: {
      type: DataTypes.STRING,
      allowNull: false,
      defaultValue: 'hatha',
    },
    difficulty_level: {
      type: DataTypes.STRING,
      allowNull: false,
      defaultValue: 'all-levels',
    },
    price_per_session: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      defaultValue: 0,
    },
    currency: {
      type: DataTypes.STRING(3),
      allowNull: false,
      defaultValue: 'INR',
    },
    requirements: {
      type: DataTypes.ARRAY(DataTypes.TEXT),
      allowNull: false,
      defaultValue: [],
    },
    equipment_needed: {
      type: DataTypes.ARRAY(DataTypes.TEXT),
      allowNull: false,
      defaultValue: [],
    },
    meetLink: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    created_at: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
    },
    updated_at: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
    },
    coordinates: {
      type: DataTypes.VIRTUAL,
      get() {
        return this.latitude != null && this.longitude != null
          ? { latitude: this.latitude, longitude: this.longitude }
          : null;
      },
    },
    location_text: {
      type: DataTypes.VIRTUAL,
      get() {
        if (this.groupType === 'offline') {
          return this.location_address || this.location?.address || null;
        }
        return null;
      },
    },
  },
  {
    tableName: 'groups',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    indexes: [
      { fields: ['instructor_id'] },
      { fields: ['is_active'] },
      { fields: ['created_at'] },
      { fields: ['groupType'] },
      { fields: ['location_address'] },
    ],
  }
);

Group.prototype.toJSON = function toJSON() {
  const values = { ...this.get() };
  values._id = values.id;
  return values;
};

module.exports = Group;
