const { DataTypes, Op } = require('sequelize');
const crypto = require('crypto');
const sequelize = require('../config/sequelize');

const SessionQRCode = sequelize.define(
  'SessionQRCode',
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    group_id: {
      type: DataTypes.UUID,
      allowNull: false,
    },
    token: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
    },
    session_date: {
      type: DataTypes.DATEONLY,
      allowNull: false,
    },
    expires_at: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    created_by: {
      type: DataTypes.UUID,
      allowNull: false,
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
    },
    usage_count: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    max_usage: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 100,
    },
    session_start_time: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    session_end_time: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    location_restriction: {
      type: DataTypes.JSONB,
      allowNull: false,
      defaultValue: { enabled: false },
    },
    qr_data: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    metadata: {
      type: DataTypes.JSONB,
      allowNull: false,
      defaultValue: {},
    },
    is_valid: {
      type: DataTypes.VIRTUAL,
      get() {
        const now = new Date();
        return (
          this.is_active &&
          new Date(this.expires_at) > now &&
          Number(this.usage_count) < Number(this.max_usage)
        );
      },
    },
    time_until_expiry: {
      type: DataTypes.VIRTUAL,
      get() {
        const now = new Date();
        const diffTime = new Date(this.expires_at) - now;
        return Math.max(0, diffTime);
      },
    },
  },
  {
    tableName: 'session_qr_codes',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    indexes: [
      { unique: true, fields: ['token'] },
      { fields: ['group_id', 'session_date'] },
      { fields: ['expires_at'] },
      { fields: ['is_active'] },
      { fields: ['created_at'] },
    ],
    hooks: {
      beforeValidate(qr) {
        if (!qr.token) {
          qr.token = crypto.randomBytes(32).toString('hex');
        }
        if (!qr.qr_data) {
          qr.qr_data = `${process.env.APP_URL || 'http://localhost:3000'}/qr/scan/${qr.token}`;
        }
      },
    },
  }
);

SessionQRCode.prototype.toJSON = function toJSON() {
  const values = { ...this.get() };
  values._id = values.id;
  return values;
};

SessionQRCode.generateForSession = async function generateForSession(groupId, sessionDate, createdBy, options = {}) {
  const sessionStartTime = options.sessionStartTime || new Date(sessionDate);
  const sessionEndTime =
    options.sessionEndTime || new Date(sessionStartTime.getTime() + 60 * 60 * 1000);
  const expiresAt = options.expiresAt || new Date(sessionEndTime.getTime() + 30 * 60 * 1000);

  return SessionQRCode.create({
    group_id: groupId,
    session_date: new Date(sessionDate).toISOString().split('T')[0],
    expires_at: expiresAt,
    created_by: createdBy,
    session_start_time: sessionStartTime,
    session_end_time: sessionEndTime,
    max_usage: options.maxUsage || 100,
    location_restriction: options.locationRestriction || { enabled: false },
    metadata: options.metadata || {},
  });
};

SessionQRCode.validateAndUse = async function validateAndUse(token, userId, location = null) {
  const qrCode = await SessionQRCode.findOne({ where: { token, is_active: true } });
  if (!qrCode) {
    throw new Error('Invalid QR code');
  }

  if (!qrCode.is_valid) {
    throw new Error('QR code has expired or reached usage limit');
  }

  const restriction = qrCode.location_restriction || { enabled: false };
  if (restriction.enabled && location) {
    const distance = calculateDistance(
      location.latitude,
      location.longitude,
      restriction.latitude,
      restriction.longitude
    );
    if (distance > restriction.radius) {
      throw new Error('You are too far from the session location');
    }
  }

  qrCode.usage_count = Number(qrCode.usage_count) + 1;
  await qrCode.save();
  return qrCode;
};

SessionQRCode.getActiveForGroup = function getActiveForGroup(groupId, sessionDate = null) {
  const where = { group_id: groupId, is_active: true };
  if (sessionDate) {
    where.session_date = new Date(sessionDate).toISOString().split('T')[0];
  } else {
    const today = new Date();
    const dateOnly = today.toISOString().split('T')[0];
    where.session_date = { [Op.gte]: dateOnly };
  }

  return SessionQRCode.findAll({
    where,
    order: [
      ['session_date', 'ASC'],
      ['created_at', 'DESC'],
    ],
  });
};

function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371e3;
  const φ1 = (lat1 * Math.PI) / 180;
  const φ2 = (lat2 * Math.PI) / 180;
  const Δφ = ((lat2 - lat1) * Math.PI) / 180;
  const Δλ = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

module.exports = SessionQRCode;
