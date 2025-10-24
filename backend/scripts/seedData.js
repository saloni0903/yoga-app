const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const dotenv = require('dotenv');

// Load Models
const User = require('../model/User');
const Group = require('../model/Group');
const GroupMember = require('../model/GroupMember');
const Attendance = require('../model/Attendance');
const SessionQRCode = require('../model/SessionQRCode');

// Configure dotenv
dotenv.config({ path: __dirname + '/../.env' });

// --- Data for Procedural Generation ---
const FIRST_NAMES = [
    'Aarav', 'Vivaan', 'Aditya', 'Vihaan', 'Arjun', 'Sai', 'Reyansh', 'Ayaan', 'Krishna', 'Ishaan',
    'Rohan', 'Prakash', 'Vikram', 'Anil', 'Suresh', 'Rajesh', 'Deepak', 'Sanjay', 'Amit', 'Sunil',
    'Meera', 'Ananya', 'Diya', 'Saanvi', 'Riya', 'Aadhya', 'Isha', 'Priya', 'Kavya', 'Sneha',
    'Pooja', 'Anita', 'Geeta', 'Seema', 'Rekha', 'Jaya', 'Nisha', 'Rani', 'Sita', 'Usha'
];
const LAST_NAMES = ['Sharma', 'Verma', 'Gupta', 'Singh', 'Patel', 'Kumar', 'Jain', 'Yadav', 'Malik', 'Das', 'Reddy', 'Chouhan', 'Mishra', 'Thakur', 'Agarwal', 'Mehra'];
const LOCATIONS_MP = ['Indore', 'Bhopal', 'Jabalpur', 'Gwalior', 'Ujjain', 'Sagar', 'Dewas', 'Satna', 'Ratlam', 'Rewa', 'Khandwa'];

const connectDB = async () => {
    try {
        const mongoURI = process.env.MONGODB_URI;
        if (!mongoURI) throw new Error('MONGODB_URI is not defined in your .env file.');
        await mongoose.connect(mongoURI);
        console.log('✅ MongoDB Connected for Seeding');
    } catch (error) {
        console.error('❌ Database connection error:', error.message);
        process.exit(1);
    }
};

/**
 * Returns a date in the past.
 * @param {number} daysAgo - Number of days to go back.
 * @returns {Date}
 */
const pastDate = (daysAgo) => {
    const date = new Date();
    date.setDate(date.getDate() - daysAgo);
    return date;
};

/**
 * Returns a date in the future.
 * @param {number} daysAhead - Number of days to go forward.
 * @returns {Date}
 */
const futureDate = (daysAhead) => {
    const date = new Date();
    date.setDate(date.getDate() + daysAhead);
    return date;
};


const seedData = async () => {
    try {
        await connectDB();
        console.log('🚀 Starting to seed data...');

        // --- 1. Clear Existing Data ---
        console.log('🗑️ Clearing existing data (Users, Groups, Members, Attendance, QRCodes)...');
        await User.deleteMany({});
        await Group.deleteMany({});
        await GroupMember.deleteMany({});
        await Attendance.deleteMany({});
        await SessionQRCode.deleteMany({});
        console.log('✅ Data cleared.');

        // --- 2. Create Admin & Instructors ---
        const defaultPassword = await bcrypt.hash('password123', 10);
        const usersToCreate = [
            // Admin
            { firstName: 'Admin', lastName: 'User', email: 'admin@yes.com', role: 'admin', location: 'Bhopal', status: 'approved', password: defaultPassword },
            
            // Instructors
            { firstName: 'Rahul', lastName: 'Sharma', email: 'rahul.s@example.com', role: 'instructor', location: 'Indore', status: 'approved', password: defaultPassword },
            { firstName: 'Priya', lastName: 'Singh', email: 'priya.k@example.com', role: 'instructor', location: 'Bhopal', status: 'approved', password: defaultPassword },
            { firstName: 'Ankit', lastName: 'Jain', email: 'ankit.j@example.com', role: 'instructor', location: 'Jabalpur', status: 'approved', password: defaultPassword },
            { firstName: 'Vikram', lastName: 'Rathore', email: 'vikram.r@example.com', role: 'instructor', location: 'Gwalior', status: 'approved', password: defaultPassword },
            { firstName: 'Manoj', lastName: 'Gupta', email: 'manoj.g@example.com', role: 'instructor', location: 'Gwalior', status: 'pending', password: defaultPassword },
            { firstName: 'Sunita', lastName: 'Verma', email: 'sunita.v@example.com', role: 'instructor', location: 'Ujjain', status: 'suspended', password: defaultPassword },
            { firstName: 'Rohit', lastName: 'Malik', email: 'rohit.m@example.com', role: 'instructor', location: 'Indore', status: 'rejected', password: defaultPassword },
            { firstName: 'Kavita', lastName: 'Mishra', email: 'kavita.m@example.com', role: 'instructor', location: 'Ujjain', status: 'pending', password: defaultPassword },
        ];

        console.log('🧑‍🏫 Creating admin and instructors...');
        const createdUsers = await User.insertMany(usersToCreate);
        
        // Get IDs of *approved* instructors for creating groups
        const approvedInstructorIds = createdUsers
            .filter(u => u.role === 'instructor' && u.status === 'approved')
            .map(u => u._id);
        
        console.log(`   - Created ${createdUsers.length} users (Admin + Instructors).`);

        // --- 3. Create Participants (Procedural) ---
        const participantsToCreate = [];
        console.log('🧘 Creating 50 participants...');
        for (let i = 0; i < 50; i++) {
            const fn = FIRST_NAMES[i % FIRST_NAMES.length];
            const ln = LAST_NAMES[i % LAST_NAMES.length];
            const loc = LOCATIONS_MP[i % LOCATIONS_MP.length];
            participantsToCreate.push({
                firstName: fn,
                lastName: ln,
                email: `${fn.toLowerCase()}.${ln.toLowerCase()}${i}@participant.com`,
                role: 'participant',
                location: loc,
                status: 'approved',
                password: defaultPassword
            });
        }
        const participantUsers = await User.insertMany(participantsToCreate);
        const participantIds = participantUsers.map(p => p._id);
        console.log(`   - Created ${participantIds.length} participants.`);

        // --- 4. Create Groups ---
        console.log('👨‍👩‍👧‍👦 Creating groups...');
        const groupsData = [
            {
                instructor_id: approvedInstructorIds[0], // Rahul
                group_name: 'Sunrise Hatha Yoga (Indore)',
                groupType: 'offline',
                location: { type: 'Point', coordinates: [75.8577, 22.7196], address: 'Nehru Park, Indore' }, // Lon, Lat
                schedule: { startTime: '06:00', endTime: '07:00', days: ['Monday', 'Wednesday', 'Friday'], startDate: pastDate(30), endDate: futureDate(180) },
                yoga_style: 'hatha', color: '#FFB300' // Amber
            },
            {
                instructor_id: approvedInstructorIds[1], // Priya
                group_name: 'Weekend Restore (Bhopal)',
                groupType: 'offline',
                location: { type: 'Point', coordinates: [77.4126, 23.2599], address: 'Shahpura Park, Bhopal' }, // Lon, Lat
                schedule: { startTime: '08:00', endTime: '09:00', days: ['Saturday', 'Sunday'], startDate: pastDate(45), endDate: futureDate(150) },
                yoga_style: 'restorative', color: '#4CAF50' // Green
            },
            {
                instructor_id: approvedInstructorIds[1], // Priya
                group_name: 'Evening Vinyasa Flow (Online)',
                groupType: 'online',
                schedule: { startTime: '18:00', endTime: '19:00', days: ['Tuesday', 'Thursday'], startDate: pastDate(15), endDate: futureDate(200) },
                yoga_style: 'vinyasa', color: '#039BE5' // Light Blue
            },
            {
                instructor_id: approvedInstructorIds[2], // Ankit
                group_name: 'Power Yoga (Jabalpur)',
                groupType: 'offline',
                location: { type: 'Point', coordinates: [79.9333, 23.1667], address: 'Bhawartal Garden, Jabalpur' }, // Lon, Lat
                schedule: { startTime: '07:00', endTime: '08:00', days: ['Tuesday', 'Thursday', 'Saturday'], startDate: pastDate(10), endDate: futureDate(100) },
                yoga_style: 'power', color: '#F44336' // Red
            },
            {
                instructor_id: approvedInstructorIds[3], // Vikram
                group_name: 'Morning Meditation (Gwalior)',
                groupType: 'offline',
                location: { type: 'Point', coordinates: [78.1828, 26.2183], address: 'Gwalior Fort, Gwalior' }, // Lon, Lat
                schedule: { startTime: '06:30', endTime: '07:30', days: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'], startDate: pastDate(5), endDate: futureDate(90) },
                yoga_style: 'other', color: '#673AB7' // Deep Purple
            },
        ];
        const createdGroups = await Group.insertMany(groupsData);
        console.log(`   - Created ${createdGroups.length} groups.`);

        // --- 5. Create Group Memberships (Procedural) ---
        console.log('🔗 Creating group memberships...');
        const membershipsData = [];
        for (const userId of participantIds) {
            // Assign each participant to at least one group
            const group1 = createdGroups[Math.floor(Math.random() * createdGroups.length)];
            membershipsData.push({ user_id: userId, group_id: group1._id, status: 'active' });

            // ~40% chance of being in a second group
            if (Math.random() > 0.6) {
                const group2 = createdGroups[Math.floor(Math.random() * createdGroups.length)];
                // Ensure it's not the same group
                if (group1._id.toString() !== group2._id.toString()) {
                    membershipsData.push({ user_id: userId, group_id: group2._id, status: 'active' });
                }
            }
        }
        await GroupMember.insertMany(membershipsData);
        console.log(`   - Created ${membershipsData.length} group memberships.`);

        // --- 6. Create Past Attendance Records (Procedural for last 30 days) ---
        console.log('📝 Creating past attendance records for last 30 days...');
        const attendanceData = [];
        const dayMap = { 'Sunday': 0, 'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4, 'Friday': 5, 'Saturday': 6 };
        
        // Get all active memberships and populate their group schedule
        const allMemberships = await GroupMember.find({ status: 'active' })
            .populate({ path: 'group_id', select: 'schedule groupType' })
            .lean();

        for (let i = 30; i >= 0; i--) { // Loop from 30 days ago to today
            const targetDate = new Date();
            targetDate.setDate(targetDate.getDate() - i);
            const dayOfWeekNum = targetDate.getDay();

            for (const member of allMemberships) {
                // Handle cases where group_id might be null if something went wrong
                if (!member.group_id || !member.group_id.schedule) continue;

                const groupSchedule = member.group_id.schedule;
                const scheduledDayNums = groupSchedule.days.map(day => dayMap[day]);

                // Check if the group has a session on this day
                if (scheduledDayNums.includes(dayOfWeekNum)) {
                    // Simulate a ~65% attendance rate
                    if (Math.random() > 0.35) {
                        const [hour, minute] = groupSchedule.startTime.split(':');
                        // Create a new date object for sessionDate to avoid mutation issues
                        const sessionDate = new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate(), parseInt(hour), parseInt(minute), 0);

                        attendanceData.push({
                            user_id: member.user_id,
                            group_id: member.group_id._id,
                            session_date: sessionDate,
                            marked_at: new Date(sessionDate.getTime() + (5 * 60 * 1000)), // 5 mins after start
                            attendance_type: (Math.random() > 0.1 ? 'present' : 'late'), // 10% chance of being late
                            location_verified: member.group_id.groupType === 'offline' // Assume verified
                        });
                    }
                }
            }
        }
        
        if (attendanceData.length > 0) {
            // Use bulkWrite to avoid duplicate key errors if a user somehow gets 
            // two identical attendance records (e.g., if member of same group twice)
            const operations = attendanceData.map(doc => ({
                updateOne: {
                    filter: { user_id: doc.user_id, group_id: doc.group_id, session_date: doc.session_date },
                    update: { $setOnInsert: doc },
                    upsert: true
                }
            }));
            const result = await Attendance.bulkWrite(operations);
            console.log(`   - Created/upserted ${result.upsertedCount} past attendance records.`);
        } else {
             console.log('   - No attendance records created.');
        }

        // --- 7. Final Output ---
        console.log('✅✅✅ Data seeding complete! ✅✅✅');

    } catch (error) {
        console.error('❌ Error during data seeding:', error);
    } finally {
        console.log('🔌 Closing MongoDB connection.');
        await mongoose.connection.close();
    }
};

// --- Execute Seeding ---
seedData();

