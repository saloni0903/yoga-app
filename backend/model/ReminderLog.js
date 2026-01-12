const { DataTypes } = require('sequelize');
const sequelize = require('../config/sequelize');

const ReminderLog = sequelize.define(
    'ReminderLog',
    {
        id: {
            type: DataTypes.UUID,
            defaultValue: DataTypes.UUIDV4,
            primaryKey: true,
        },
        groupId: {
            type: DataTypes.UUID,
            allowNull: false,
        },
        sessionDateISO: {
            type: DataTypes.STRING,
            allowNull: false,
        },
        reminderType: {
            type: DataTypes.ENUM('1hr', '24hr'),
            allowNull: false,
        },
    },
    {
        tableName: 'reminder_logs',
        timestamps: true,
        indexes: [
            {
                unique: true,
                fields: ['groupId', 'sessionDateISO', 'reminderType'],
            },
        ],
    }
);

ReminderLog.prototype.toJSON = function toJSON() {
    const values = { ...this.get() };
    values._id = values.id;
    return values;
};

module.exports = ReminderLog;