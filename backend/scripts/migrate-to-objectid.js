// backend/scripts/migrate-to-objectid.js
//
// This script was used for a legacy MongoDB migration and is not applicable
// after switching the backend to PostgreSQL + Sequelize (UUID primary keys).
//
// Keeping it as a no-op so `npm run migrate:objectid` doesn't crash.

console.log('This migration script is obsolete.');
console.log('The backend now uses PostgreSQL + Sequelize with UUID primary keys.');
console.log('If you need data migration from MongoDB -> Postgres, we should create a new ETL script.');
process.exit(0);
