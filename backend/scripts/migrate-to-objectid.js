// backend/scripts/migrate-to-objectid.js
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config({ path: __dirname + '/../.env' });

const COLLECTIONS = {
    USERS: 'users',
    GROUPS: 'groups',
    GROUP_MEMBERS: 'groupmembers',
    ATTENDANCES: 'attendances',
    SESSION_QR_CODES: 'sessionqrcodes',
    SESSIONS: 'sessions'
};

const connectDB = async () => {
    try {
        const mongoURI = process.env.MONGODB_URI;
        if (!mongoURI) throw new Error('MONGODB_URI is not defined in your .env file.');
        await mongoose.connect(mongoURI);
        console.log('✅ MongoDB Connected for Migration');
    } catch (error) {
        console.error('❌ MongoDB Connection Error:', error.message);
        process.exit(1);
    }
};

async function migrate() {
    await connectDB();
    const session = await mongoose.startSession();
    session.startTransaction();
    console.log('🚀 Starting migration from String UUIDs to ObjectIds...');

    const idMap = new Map();

    try {
        // --- STEP 1: MIGRATE PARENT COLLECTION (USERS) & CLEAN DUPLICATES ---
        console.log(`\n--- Migrating Collection: ${COLLECTIONS.USERS} ---`);
        const users = await mongoose.connection.collection(COLLECTIONS.USERS).find({}, { session }).toArray();
        const seenEmails = new Set();
        
        for (const user of users) {
            // NEW: Check for duplicate email before any other operation
            if (user.email && seenEmails.has(user.email)) {
                console.warn(`  ⚠️ WARNING: Found duplicate email "${user.email}". Deleting corrupt document with _id: ${user._id}.`);
                await mongoose.connection.collection(COLLECTIONS.USERS).deleteOne({ _id: user._id }, { session });
                continue; // Skip to the next user
            }
            if(user.email) seenEmails.add(user.email);

            const oldId = user._id.toString();
            if (mongoose.Types.ObjectId.isValid(oldId)) {
                idMap.set(oldId, user._id);
                continue;
            }
            const newId = new mongoose.Types.ObjectId();
            idMap.set(oldId, newId);
            
            const newUser = { ...user, _id: newId };
            await mongoose.connection.collection(COLLECTIONS.USERS).insertOne(newUser, { session });
            await mongoose.connection.collection(COLLECTIONS.USERS).deleteOne({ _id: oldId }, { session });
        }
        console.log(`✅ Migrated and cleaned ${users.length} documents in [${COLLECTIONS.USERS}].`);


        // --- STEP 2: MIGRATE CHILD COLLECTIONS ---
        console.log(`\n--- Migrating Collection: ${COLLECTIONS.GROUPS} ---`);
        const groups = await mongoose.connection.collection(COLLECTIONS.GROUPS).find({}, { session }).toArray();
        for (const group of groups) {
            const oldId = group._id.toString();
            if (mongoose.Types.ObjectId.isValid(oldId)) {
                idMap.set(oldId, group._id);
                continue;
            }
            const newId = new mongoose.Types.ObjectId();
            idMap.set(oldId, newId);

            const newInstructorId = idMap.get(group.instructor_id.toString());
            if (!newInstructorId) console.warn(`  ⚠️ WARNING: Could not map instructor_id for group "${oldId}".`);

            const newGroup = { ...group, _id: newId, ...(newInstructorId && { instructor_id: newInstructorId }) };
            await mongoose.connection.collection(COLLECTIONS.GROUPS).insertOne(newGroup, { session });
            await mongoose.connection.collection(COLLECTIONS.GROUPS).deleteOne({ _id: oldId }, { session });
        }
        console.log(`✅ Migrated ${groups.length} documents in [${COLLECTIONS.GROUPS}].`);
        
        console.log(`\n--- Migrating Collection: ${COLLECTIONS.SESSION_QR_CODES} ---`);
        const qrCodes = await mongoose.connection.collection(COLLECTIONS.SESSION_QR_CODES).find({}, { session }).toArray();
        for (const qr of qrCodes) {
            const oldId = qr._id.toString();
            if (mongoose.Types.ObjectId.isValid(oldId)) {
                idMap.set(oldId, qr._id);
                continue;
            }
            const newId = new mongoose.Types.ObjectId();
            idMap.set(oldId, newId);

            const newGroupId = idMap.get(qr.group_id.toString());
            const newCreatedById = idMap.get(qr.created_by.toString());

            const newQr = { 
                ...qr, 
                _id: newId, 
                ...(newGroupId && { group_id: newGroupId }),
                ...(newCreatedById && { created_by: newCreatedById })
            };
            delete newQr.token; 
            await mongoose.connection.collection(COLLECTIONS.SESSION_QR_CODES).insertOne(newQr, { session });
            await mongoose.connection.collection(COLLECTIONS.SESSION_QR_CODES).deleteOne({ _id: oldId }, { session });
        }
        console.log(`✅ Migrated ${qrCodes.length} documents in [${COLLECTIONS.SESSION_QR_CODES}].`);


        // --- STEP 3: UPDATE FOREIGN KEYS IN REMAINING COLLECTIONS ---
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
                    if (doc[fk] && !mongoose.Types.ObjectId.isValid(doc[fk].toString())) {
                        const newFkId = idMap.get(doc[fk].toString());
                        if (newFkId) {
                            updatePayload[fk] = newFkId;
                            hasUpdate = true;
                        } else {
                             console.warn(`  ⚠️ WARNING: In [${collectionInfo.name}], could not map FK "${fk}" for document "${doc._id}".`);
                        }
                    }
                }
                if (hasUpdate) {
                    await mongoose.connection.collection(collectionInfo.name).updateOne({ _id: doc._id }, { $set: updatePayload }, { session });
                }
            }
            console.log(`✅ Processed FKs for ${documents.length} documents in [${collectionInfo.name}].`);
        }

        await session.commitTransaction();
        console.log('\n🎉 Transaction committed. Migration successful.');

    } catch (error) {
        await session.abortTransaction();
        console.error('❌ Migration failed and transaction was rolled back:', error);
        throw error;
    } finally {
        session.endSession();
    }

    await mongoose.connection.close();
    console.log('  - Database connection closed.');
}

migrate().catch(() => process.exit(1));