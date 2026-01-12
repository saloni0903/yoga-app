const { DataTypes } = require('sequelize');
const sequelize = require('../config/sequelize');

const HealthProfile = sequelize.define(
  'HealthProfile',
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
    responses: {
      type: DataTypes.JSONB,
      allowNull: false,
      defaultValue: {},
    },
    totalScore: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
    date: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
    },
  },
  {
    tableName: 'health_profiles',
    timestamps: false,
    indexes: [{ fields: ['user_id'] }, { fields: ['date'] }],
  }
);

HealthProfile.prototype.toJSON = function toJSON() {
  const values = { ...this.get() };
  values._id = values.id;
  return values;
};

module.exports = HealthProfile;