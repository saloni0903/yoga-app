// backend/config/database.js
const sequelize = require('./sequelize');
require('dotenv').config();

// Register models + associations
require('../model');

function getValidatedSchema() {
  const schema = String(process.env.PGSCHEMA || '').trim();
  if (!schema) return null;
  if (schema === 'public') return null;
  // Prevent SQL injection when we use the schema in SET search_path.
  if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(schema)) {
    throw new Error(
      `Invalid PGSCHEMA "${schema}". Use only letters, numbers, and underscore; must not start with a number.`
    );
  }
  return schema;
}

const connectDB = async () => {
  try {
    await sequelize.authenticate();
    console.log('✅ Postgres Connected (Sequelize)');

    const schema = getValidatedSchema();
    if (schema) {
      // Create schema if missing (works if the DB user has CREATE on the database).
      await sequelize.createSchema(schema).catch(async (err) => {
        // If schema already exists, ignore.
        if (err && (err.name === 'SequelizeDatabaseError' || err.name === 'SequelizeBaseError')) {
          const msg = String(err.message || '');
          if (msg.toLowerCase().includes('already exists')) return;
        }
        throw err;
      });

      // Ensure this connection uses the intended schema first.
      await sequelize.query(`SET search_path TO "${schema}", public;`);
    }

    // For initial migration, we sync the schema automatically.
    // In production, consider replacing this with migrations.
    const shouldSync = process.env.DB_SYNC !== 'false';
    if (shouldSync) {
      await sequelize.sync();
      console.log('✅ DB schema synced');
    }
  } catch (error) {
    console.error('Postgres connection error:', error);
    process.exit(1);
  }
};

module.exports = connectDB;