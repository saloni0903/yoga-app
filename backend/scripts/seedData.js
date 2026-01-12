const dotenv = require('dotenv');
dotenv.config({ path: __dirname + '/../.env' });

const connectDB = require('../config/database');
const { sequelize, User, Group, GroupMember, Attendance, SessionQRCode } = require('../model');

function toDateOnly(value) {
    return new Date(value).toISOString().split('T')[0];
}

function daysAgo(n) {
    const d = new Date();
    d.setDate(d.getDate() - n);
    return d;
}

function pick(arr) {
    return arr[Math.floor(Math.random() * arr.length)];
}

// --- Lightweight sample data ---
const FIRST_NAMES = [
    'Aarav', 'Vivaan', 'Aditya', 'Vihaan', 'Arjun', 'Sai', 'Reyansh', 'Ayaan', 'Krishna', 'Ishaan',
    'Meera', 'Ananya', 'Diya', 'Saanvi', 'Riya', 'Aadhya', 'Isha', 'Priya', 'Kavya', 'Sneha',
];
const LAST_NAMES = ['Sharma', 'Verma', 'Gupta', 'Singh', 'Patel', 'Kumar', 'Jain', 'Yadav', 'Malik', 'Das'];
const LOCATIONS_MP = ['Indore', 'Bhopal', 'Jabalpur', 'Gwalior', 'Ujjain'];

async function seed() {
    await connectDB();

    if (String(process.env.SEED_RESET || '').toLowerCase() === 'true') {
        console.log('⚠️  SEED_RESET=true -> dropping & recreating tables');
        await sequelize.sync({ force: true });
    }

    const adminEmail = 'admin@yoga.gov.in';
    const instructorEmail = 'instructor@yoga.gov.in';

    const [adminUser] = await User.findOrCreate({
        where: { email: adminEmail },
        defaults: {
            firstName: 'Aayush',
            lastName: 'Admin',
            email: adminEmail,
            password: 'AdminPassword123!'.trim(),
            role: 'admin',
            status: 'approved',
            location: 'Indore, MP',
        },
    });

    const [instructor] = await User.findOrCreate({
        where: { email: instructorEmail },
        defaults: {
            firstName: 'Isha',
            lastName: 'Instructor',
            email: instructorEmail,
            password: 'InstructorPassword123!'.trim(),
            role: 'instructor',
            status: 'approved',
            location: 'Bhopal, MP',
        },
    });

    const participants = [];
    for (let i = 0; i < 10; i++) {
        const firstName = pick(FIRST_NAMES);
        const lastName = pick(LAST_NAMES);
        const email = `participant${i + 1}@yoga.gov.in`;

        const [participant] = await User.findOrCreate({
            where: { email },
            defaults: {
                firstName,
                lastName,
                email,
                password: 'ParticipantPassword123!'.trim(),
                role: 'participant',
                status: 'approved',
                location: `${pick(LOCATIONS_MP)}, MP`,
                isHealthProfileCompleted: false,
            },
        });
        participants.push(participant);
    }

    const schedule = {
        startDate: toDateOnly(daysAgo(30)),
        endDate: toDateOnly(daysAgo(-30)),
        days: ['Monday', 'Wednesday', 'Friday'],
        startTime: '07:00',
        endTime: '08:00',
    };

    const [group] = await Group.findOrCreate({
        where: { group_name: 'Morning Hatha Yoga (Seeded)' },
        defaults: {
            instructor_id: instructor.id,
            groupType: 'offline',
            group_name: 'Morning Hatha Yoga (Seeded)',
            schedule,
            location: { address: 'Indore, MP', latitude: 22.7196, longitude: 75.8577 },
            location_address: 'Indore, MP',
            latitude: 22.7196,
            longitude: 75.8577,
            color: '#2E7D6E',
            is_active: true,
            max_participants: 20,
            yoga_style: 'hatha',
            difficulty_level: 'all-levels',
            price_per_session: 0,
            currency: 'INR',
            requirements: ['yoga mat'],
            equipment_needed: ['mat'],
        },
    });

    for (const participant of participants) {
        await GroupMember.findOrCreate({
            where: { user_id: participant.id, group_id: group.id },
            defaults: {
                user_id: participant.id,
                group_id: group.id,
                status: 'active',
                role: 'member',
                payment_status: 'paid',
                attendance_count: 0,
            },
        });
    }

    // Create a few attendance records over the last week
    for (const participant of participants) {
        for (let i = 0; i < 5; i++) {
            const sessionDateOnly = toDateOnly(daysAgo(i));

            await Attendance.findOrCreate({
                where: { user_id: participant.id, group_id: group.id, session_date: sessionDateOnly },
                defaults: {
                    user_id: participant.id,
                    group_id: group.id,
                    session_date: sessionDateOnly,
                    attendance_type: Math.random() < 0.85 ? 'present' : 'absent',
                    session_duration: 60,
                    location_verified: true,
                    gps_coordinates: { latitude: 22.7196, longitude: 75.8577 },
                },
            });
        }
    }

    // Create an active QR code for today
    await SessionQRCode.generateForSession(group.id, new Date(), instructor.id, {
        maxUsage: 100,
        metadata: { seeded: true },
    });

    console.log('✅ Seed complete');
    console.log(`Admin: ${adminUser.email}`);
    console.log(`Instructor: ${instructor.email}`);
    console.log(`Group: ${group.group_name}`);
}

seed()
    .catch(err => {
        console.error('❌ Seeding failed:', err);
        process.exitCode = 1;
    })
    .finally(async () => {
        await sequelize.close();
    });

