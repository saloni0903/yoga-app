// backend/scripts/migrate-to-objectid.js
const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Configure dotenv to find the .env file in the root of the backend folder
dotenv.config({ path: __dirname + '/../.env' });

/*
 * =================================================================================
 * SCRIPT OVERVIEW
 * =================================================================================
 * This is a one-time migration script to convert all primary and foreign keys
 * from insecure, inefficient String UUIDs to native MongoDB ObjectIds.
 *
 * EXECUTION ORDER IS CRITICAL:
 * 1.  Backup your database. This script performs destructive updates.
 * 2.  Run this script against a STAGING/DEVELOPMENT database first.
 * 3.  The script first migrates "parent" collections (Users).
 * 4.  It then uses a map of old IDs to new IDs to update "child" collections
 * (Groups, GroupMembers, Attendances, etc.) that reference the parents.
 * 5.  Once the data is successfully migrated, the associated Pull Request
 * containing the Mongoose model changes can be safely merged and deployed.
 * =================================================================================
 */

// We don't need the full models, just the collection names
const COLLECTIONS = {
    USERS: 'users',
    GROUPS: 'groups',
    GROUP_MEMBERS: 'groupmembers',
    ATTENDANCES: 'attendances',
    SESSION_QR_CODES: 'sessionqrcodes',
    SESSIONS: 'sessions' // The obsolete collection
};

const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGODB_URI;
    if (!mongoURI) {
        throw new Error('MONGODB_URI is not defined in your .env file.');
    }
    await mongoose.connect(mongoURI);
    console.log('✅ MongoDB Connected for Migration');
  } catch (error) {
    console.error('❌ MongoDB Connection Error:', error.message);
    process.exit(1);
  }
};

async function migrate() {
  await connectDB();
  console.log('🚀 Starting migration from String UUIDs to ObjectIds...');

  // This map is the single source of truth for the migration.
  // It will store { 'old_string_uuid': newObjectId, ... }
  const idMap = new Map();

  // --- STEP 1: MIGRATE PARENT COLLECTIONS & BUILD THE ID MAP ---
  // Users are a parent collection. They don't reference other custom collections.
  console.log(`\n--- Migrating Collection: ${COLLECTIONS.USERS} ---`);
  const users = await mongoose.connection.collection(COLLECTIONS.USERS).find({}).toArray();
  for (const user of users) {
    const oldId = user._id.toString();
    if (mongoose.Types.ObjectId.isValid(oldId)) {
        console.log(`  - Skipping already migrated user ${oldId}`);
        idMap.set(oldId, user._id); // Ensure map is populated for existing ObjectIds
        continue;
    }
    const newId = new mongoose.Types.ObjectId();
    idMap.set(oldId, newId);
    await mongoose.connection.collection(COLLECTIONS.USERS).updateOne({ _id: oldId }, { $set: { _id: newId } });
  }
  console.log(`✅ Migrated _id for ${users.length} documents in [${COLLECTIONS.USERS}].`);


  // --- STEP 2: MIGRATE CHILD COLLECTIONS, UPDATING _id AND FOREIGN KEYS ---
  // Groups reference Users.
  console.log(`\n--- Migrating Collection: ${COLLECTIONS.GROUPS} ---`);
  const groups = await mongoose.connection.collection(COLLECTIONS.GROUPS).find({}).toArray();
  for (const group of groups) {
    const oldId = group._id.toString();
    const newId = mongoose.Types.ObjectId.isValid(oldId) ? group._id : new mongoose.Types.ObjectId();
    idMap.set(oldId, newId);

    const newInstructorId = idMap.get(group.instructor_id.toString());
    if (!newInstructorId) {
        console.warn(`  ⚠️ WARNING: Could not map instructor_id "${group.instructor_id}" for group "${oldId}". Skipping FK update.`);
    }

    await mongoose.connection.collection(COLLECTIONS.GROUPS).updateOne(
      { _id: group._id },
      { $set: { 
          _id: newId,
          ...(newInstructorId && { instructor_id: newInstructorId })
        } 
      }
    );
  }
  console.log(`✅ Migrated _id and foreign keys for ${groups.length} documents in [${COLLECTIONS.GROUPS}].`);

  // SessionQRCodes reference Groups and Users.
  console.log(`\n--- Migrating Collection: ${COLLECTIONS.SESSION_QR_CODES} ---`);
  const qrCodes = await mongoose.connection.collection(COLLECTIONS.SESSION_QR_CODES).find({}).toArray();
  for (const qr of qrCodes) {
      const oldId = qr._id.toString();
      const newId = mongoose.Types.ObjectId.isValid(oldId) ? qr._id : new mongoose.Types.ObjectId();
      idMap.set(oldId, newId);

      const newGroupId = idMap.get(qr.group_id.toString());
      const newCreatedById = idMap.get(qr.created_by.toString());

      if (!newGroupId) console.warn(`  ⚠️ WARNING: Could not map group_id "${qr.group_id}" for QR Code "${oldId}".`);
      if (!newCreatedById) console.warn(`  ⚠️ WARNING: Could not map created_by "${qr.created_by}" for QR Code "${oldId}".`);
      
      await mongoose.connection.collection(COLLECTIONS.SESSION_QR_CODES).updateOne(
          { _id: qr._id },
          { $set: {
              _id: newId,
              ...(newGroupId && { group_id: newGroupId }),
              ...(newCreatedById && { created_by: newCreatedById })
          }}
      );
  }
  console.log(`✅ Migrated _id and foreign keys for ${qrCodes.length} documents in [${COLLECTIONS.SESSION_QR_CODES}].`);


  // --- STEP 3: MIGRATE COLLECTIONS WITH MULTIPLE FOREIGN KEYS ---
  // GroupMembers, Attendances, Sessions reference multiple collections that are now in our idMap.
  const collectionsToUpdateFks = [
    { name: COLLECTIONS.GROUP_MEMBERS, fks: ['user_id', 'group_id'] },
    { name: COLLECTIONS.SESSIONS, fks: ['group_id', 'instructor_id'] },
    { name: COLLECTIONS.ATTENDANCES, fks: ['user_id', 'group_id', 'qr_code_id'] }
  ];

  for (const collectionInfo of collectionsToUpdateFks) {
    console.log(`\n--- Updating Foreign Keys in Collection: ${collectionInfo.name} ---`);
    const documents = await mongoose.connection.collection(collectionInfo.name).find({}).toArray();

    for (const doc of documents) {
      const updatePayload = {};
      let hasUpdate = false;

      for (const fk of collectionInfo.fks) {
        if (doc[fk]) {
          const oldFkId = doc[fk].toString();
          if (!mongoose.Types.ObjectId.isValid(oldFkId)) {
            const newFkId = idMap.get(oldFkId);
            if (newFkId) {
              updatePayload[fk] = newFkId;
              hasUpdate = true;
            } else {
              console.warn(`  ⚠️ WARNING: In [${collectionInfo.name}], could not map FK "${fk}" with value "${oldFkId}" for document "${doc._id}".`);
            }
          }
        }
      }

      if (hasUpdate) {
        await mongoose.connection.collection(collectionInfo.name).updateOne({ _id: doc._id }, { $set: updatePayload });
      }
    }
    console.log(`✅ Processed FKs for ${documents.length} documents in [${collectionInfo.name}].`);
  }

  console.log('\n🎉 Migration process complete. Please manually verify the data in your database.');
  await mongoose.connection.close();
  console.log('  - Database connection closed.');
}

// Execute the migration
migrate().catch(err => {
  console.error('❌ Migration failed with a fatal error:', err);
  mongoose.connection.close().then(() => process.exit(1));
});
