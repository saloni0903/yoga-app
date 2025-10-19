// backend/scripts/seedData.js
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const dotenv = require('dotenv');

const User = require('../model/User');
const Group = require('../model/Group');
const GroupMember = require('../model/GroupMember');
const Attendance = require('../model/Attendance');
const SessionQRCode = require('../model/SessionQRCode'); // <-- Required for cleaning

dotenv.config({ path: __dirname + '/../.env' });

const connectDB = async () => {
    try {
        const mongoURI = process.env.MONGODB_URI;
        if (!mongoURI) throw new Error('MONGODB_URI is not defined in your .env file.');
        await mongoose.connect(mongoURI);
        console.log('✅ MongoDB Connected for Seeding');
    } catch (error) {
        console.error('Database connection error:', error.message);
        process.exit(1);
    }
};

const seedData = async () => {
    try {
        await connectDB();
        console.log('Starting to seed data...');

        console.log('Clearing existing data...');
        await User.deleteMany({});
        await Group.deleteMany({});
        await GroupMember.deleteMany({});
        await Attendance.deleteMany({});
        await SessionQRCode.deleteMany({}); // <-- THE CRITICAL FIX

        const instructorsData = [
            { firstName: 'Rahul', lastName: 'Sharma', email: 'rahulsharma@gmail.com', role: 'instructor', location: 'Indore', status: 'approved' },
            { firstName: 'Adi', lastName: 'Jain', email: 'adijain@gmail.com', role: 'instructor', location: 'Bhopal', status: 'approved' },
        ];
        
        const instructorIds = {};
        console.log('Creating instructors...');
        for (const instData of instructorsData) {
            const password = await bcrypt.hash('password123', 10);
            const user = new User({ ...instData, password });
            const savedUser = await user.save();
            instructorIds[instData.email] = savedUser._id;
        }

        const participantsData = [
             { firstName: 'John', lastName: 'Doe', email: 'john.doe@example.com', role: 'participant', location: 'Indore' },
             { firstName: 'Jane', lastName: 'Smith', email: 'jane.smith@example.com', role: 'participant', location: 'Indore' },
        ];
        
        const participantIds = {};
        console.log('Creating participants...');
        for (const partData of participantsData) {
            const password = await bcrypt.hash('password123', 10);
            const user = new User({ ...partData, password });
            const savedUser = await user.save();
            participantIds[partData.email] = savedUser._id;
        }

        console.log('Creating groups...');
        const groupsData = [
            {
                instructor_id: instructorIds['rahulsharma@gmail.com'],
                group_name: 'Sunrise Hatha Yoga',
                groupType: 'offline',
                location: { type: 'Point', coordinates: [75.8577, 22.7196], address: 'Nehru Park, Indore' },
                schedule: {
                    startTime: '06:00', endTime: '07:00',
                    days: ['Monday', 'Wednesday', 'Friday'],
                    startDate: new Date('2025-10-01'), endDate: new Date('2026-09-30')
                },
                yoga_style: 'hatha'
            },
            {
                instructor_id: instructorIds['adijain@gmail.com'],
                group_name: 'Evening Vinyasa Flow',
                groupType: 'online',
                schedule: {
                    startTime: '18:00', endTime: '19:00',
                    days: ['Tuesday', 'Thursday'],
                    startDate: new Date('2025-10-01'), endDate: new Date('2026-09-30')
                },
                yoga_style: 'vinyasa'
            },
        ];

        const groupIds = {};
        for (const groupData of groupsData) {
            const group = new Group(groupData);
            const savedGroup = await group.save();
            groupIds[savedGroup.group_name] = savedGroup._id;
        }

        console.log('Creating group members...');
        await GroupMember.create([
            { user_id: participantIds['john.doe@example.com'], group_id: groupIds['Sunrise Hatha Yoga'] },
            { user_id: participantIds['jane.smith@example.com'], group_id: groupIds['Sunrise Hatha Yoga'] },
            { user_id: participantIds['john.doe@example.com'], group_id: groupIds['Evening Vinyasa Flow'] },
        ]);

        console.log('✅ Data seeding complete!');
    } catch (error) {
        console.error('Error seeding data:', error);
    } finally {
        mongoose.connection.close();
    }
};

seedData();