const { Sequelize } = require('sequelize');
require('dotenv').config();

function getPgSchema() {
  const schema = (process.env.PGSCHEMA || '').trim();
  return schema || 'public';
}

function buildSequelize() {
  const schema = getPgSchema();

  const commonOptions = {
    dialect: 'postgres',
    logging: process.env.SQL_LOGGING === 'true' ? console.log : false,
    // If you set PGSCHEMA to a non-public schema, Sequelize will create tables/enums there.
    define: schema && schema !== 'public' ? { schema } : {},
    // Helps raw queries resolve unqualified table names.
    searchPath: schema && schema !== 'public' ? schema : undefined,
  };

  // Prefer a single DATABASE_URL (common on Render/Heroku) if present.
  // Example: postgres://user:pass@host:5432/dbname
  const databaseUrl = process.env.DATABASE_URL;

  if (databaseUrl) {
    return new Sequelize(databaseUrl, {
      ...commonOptions,
      dialectOptions:
        process.env.NODE_ENV === 'production'
          ? {
              ssl: {
                require: true,
                rejectUnauthorized: false,
              },
            }
          : {},
    });
  }

  // Otherwise use discrete env vars.
  const host = process.env.PGHOST || 'localhost';
  const port = Number(process.env.PGPORT || 5432);
  const database = process.env.PGDATABASE || 'yoga_app';
  const username = process.env.PGUSER || 'postgres';
  const password = process.env.PGPASSWORD || '';

  return new Sequelize(database, username, password, {
    host,
    port,
    ...commonOptions,
    dialectOptions:
      process.env.NODE_ENV === 'production'
        ? {
            ssl: {
              require: true,
              rejectUnauthorized: false,
            },
          }
        : {},
  });
}

module.exports = buildSequelize();
