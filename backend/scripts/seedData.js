const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
require('dotenv').config();

// Import models
const User = require('../model/User');
const Group = require('../model/Group');
const GroupMember = require('../model/GroupMember');
const Attendance = require('../model/Attendance');
const SessionQRCode = require('../model/SessionQRCode');

// Connect to database
const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGODB_URI || 'mongodb://localhost:27017/yoga_app';
    
    // Connection options
    const options = {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    };

    // Add SSL options for MongoDB Atlas or remote connections
    if (mongoURI.includes('mongodb+srv://') || mongoURI.includes('ssl=true')) {
      options.ssl = true;
      options.sslValidate = false; // Disable SSL validation for development
      options.tlsAllowInvalidCertificates = true;
      options.tlsAllowInvalidHostnames = true;
    }

    const conn = await mongoose.connect(mongoURI, options);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error('Database connection error:', error);
    console.log('Trying to connect to local MongoDB...');
    
    // Fallback to local MongoDB
    try {
      const conn = await mongoose.connect('mongodb://localhost:27017/yoga_app', {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });
      console.log(`MongoDB Connected (Local): ${conn.connection.host}`);
    } catch (localError) {
      console.error('Local MongoDB connection also failed:', localError);
      console.log('Please make sure MongoDB is running locally or check your MONGODB_URI in .env file');
      process.exit(1);
    }
  }
};

// Seed data
const seedData = async () => {
  try {
    console.log('Starting to seed data...');

    // Clear existing data
    await User.deleteMany({});
    await Group.deleteMany({});
    await GroupMember.deleteMany({});
    await Attendance.deleteMany({});
    await SessionQRCode.deleteMany({});

    console.log('Cleared existing data');

    // Create instructors
    const instructor1 = new User({
      email: 'sarah.yoga@example.com',
      password: 'password123',
      firstName: 'Sarah',
      lastName: 'Johnson',
      role: 'instructor',
      phone: '+1234567890',
      location: 'New York, NY',
      dateOfBirth: new Date('1985-03-15'),
      preferences: {
        notifications: { email: true, sms: false, push: true },
        yogaLevel: 'advanced'
      }
    });

    const instructor2 = new User({
      email: 'mike.zen@example.com',
      password: 'password123',
      firstName: 'Mike',
      lastName: 'Chen',
      role: 'instructor',
      phone: '+1234567891',
      location: 'Los Angeles, CA',
      dateOfBirth: new Date('1980-07-22'),
      preferences: {
        notifications: { email: true, sms: true, push: true },
        yogaLevel: 'advanced'
      }
    });

    await instructor1.save();
    await instructor2.save();
    console.log('Created instructors');

    // Create participants
    const participants = [];
    const locations = ['New York, NY', 'Los Angeles, CA', 'Chicago, IL', 'Houston, TX', 'Phoenix, AZ'];
    for (let i = 1; i <= 10; i++) {
      const participant = new User({
        email: `participant${i}@example.com`,
        password: 'password123',
        firstName: `Participant${i}`,
        lastName: `Last${i}`,
        role: 'participant',
        phone: `+12345678${90 + i}`,
        location: locations[i % locations.length],
        dateOfBirth: new Date(1990 + i, 0, 1),
        preferences: {
          notifications: { email: true, sms: false, push: true },
          yogaLevel: i % 3 === 0 ? 'beginner' : i % 3 === 1 ? 'intermediate' : 'advanced'
        }
      });
      await participant.save();
      participants.push(participant);
    }
    console.log('Created participants');

    // Create groups
    const group1 = new Group({
      instructor_id: instructor1._id,
      group_name: 'Morning Vinyasa Flow',
      location: 'New York, NY',
      location_text: 'Central Park, New York, NY',
      latitude: 40.785091,
      longitude: -73.968285,
      timings_text: 'Monday, Wednesday, Friday 7:00 AM - 8:00 AM',
      description: 'Start your day with an energizing vinyasa flow practice',
      yoga_style: 'vinyasa',
      difficulty_level: 'intermediate',
      session_duration: 60,
      price_per_session: 15,
      max_participants: 20
    });

    const group2 = new Group({
      instructor_id: instructor2._id,
      group_name: 'Evening Hatha Yoga',
      location: 'Los Angeles, CA',
      location_text: 'Yoga Studio Downtown, 123 Main St, Los Angeles, CA',
      latitude: 34.052235,
      longitude: -118.243685,
      timings_text: 'Tuesday, Thursday 6:00 PM - 7:00 PM',
      description: 'Gentle hatha yoga for relaxation and stress relief',
      yoga_style: 'hatha',
      difficulty_level: 'beginner',
      session_duration: 60,
      price_per_session: 12,
      max_participants: 15
    });

    const group3 = new Group({
      instructor_id: instructor1._id,
      group_name: 'Weekend Ashtanga Intensive',
      location: 'New York, NY',
      location_text: 'Beach Yoga Spot, Coney Island, NY',
      latitude: 40.574926,
      longitude: -73.985949,
      timings_text: 'Saturday 9:00 AM - 11:00 AM',
      description: 'Intensive ashtanga practice for advanced practitioners',
      yoga_style: 'ashtanga',
      difficulty_level: 'advanced',
      session_duration: 120,
      price_per_session: 25,
      max_participants: 10
    });

    await group1.save();
    await group2.save();
    await group3.save();
    console.log('Created groups');

    // Create group memberships
    const memberships = [];
    
    // Add participants to group 1
    for (let i = 0; i < 8; i++) {
      const membership = new GroupMember({
        user_id: participants[i]._id,
        group_id: group1._id,
        status: 'active',
        payment_status: i % 2 === 0 ? 'paid' : 'pending'
      });
      await membership.save();
      memberships.push(membership);
    }

    // Add participants to group 2
    for (let i = 2; i < 7; i++) {
      const membership = new GroupMember({
        user_id: participants[i]._id,
        group_id: group2._id,
        status: 'active',
        payment_status: 'paid'
      });
      await membership.save();
      memberships.push(membership);
    }

    // Add participants to group 3
    for (let i = 5; i < 10; i++) {
      const membership = new GroupMember({
        user_id: participants[i]._id,
        group_id: group3._id,
        status: 'active',
        payment_status: 'paid'
      });
      await membership.save();
      memberships.push(membership);
    }

    console.log('Created group memberships');

    // Create some attendance records
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    // Group 1 attendance for yesterday
    const group1Members = memberships.filter(m => m.group_id.toString() === group1._id.toString());
    for (let i = 0; i < 6; i++) {
      const attendance = new Attendance({
        user_id: group1Members[i].user_id,
        group_id: group1._id,
        session_date: yesterday,
        attendance_type: i === 5 ? 'late' : 'present'
      });
      await attendance.save();
    }

    // Group 2 attendance for yesterday
    const group2Members = memberships.filter(m => m.group_id.toString() === group2._id.toString());
    for (let i = 0; i < 4; i++) {
      const attendance = new Attendance({
        user_id: group2Members[i].user_id,
        group_id: group2._id,
        session_date: yesterday,
        attendance_type: 'present'
      });
      await attendance.save();
    }

    console.log('Created attendance records');

    // Create QR codes for today's sessions
    const todayMorning = new Date(today);
    todayMorning.setHours(7, 0, 0, 0);
    const todayEvening = new Date(today);
    todayEvening.setHours(18, 0, 0, 0);
    
    // Create QR codes manually to ensure token generation
    const qrCode1 = new SessionQRCode({
      group_id: group1._id,
      session_date: today,
      token: crypto.randomBytes(32).toString('hex'),
      expires_at: new Date(todayMorning.getTime() + 90 * 60 * 1000), // 90 minutes after session start
      created_by: instructor1._id,
      session_start_time: todayMorning,
      session_end_time: new Date(todayMorning.getTime() + 60 * 60 * 1000), // 1 hour later
      max_usage: 20
    });
    await qrCode1.save();

    const qrCode2 = new SessionQRCode({
      group_id: group2._id,
      session_date: today,
      token: crypto.randomBytes(32).toString('hex'),
      expires_at: new Date(todayEvening.getTime() + 90 * 60 * 1000), // 90 minutes after session start
      created_by: instructor2._id,
      session_start_time: todayEvening,
      session_end_time: new Date(todayEvening.getTime() + 60 * 60 * 1000), // 1 hour later
      max_usage: 15
    });
    await qrCode2.save();

    console.log('Created QR codes');

    console.log('Data seeding completed successfully!');
    console.log('\nSample data created:');
    console.log('- 2 Instructors');
    console.log('- 10 Participants');
    console.log('- 3 Groups');
    console.log('- Multiple group memberships');
    console.log('- Sample attendance records');
    console.log('- QR codes for today\'s sessions');
    
    console.log('\nTest credentials:');
    console.log('Instructor 1: sarah.yoga@example.com / password123');
    console.log('Instructor 2: mike.zen@example.com / password123');
    console.log('Participants: participant1@example.com to participant10@example.com / password123');

  } catch (error) {
    console.error('Error seeding data:', error);
  } finally {
    mongoose.connection.close();
  }
};

// Run the seed function
connectDB().then(() => {
  seedData();
});
// 
// Updated List of available APIs and their sample responses:
//
// 1. POST /api/auth/register
//    - Registers a new user (instructor or participant).
//    - Request body: { firstName, lastName, email, password, role }
//    - Response:
//      {
//        "success": true,
//        "message": "User registered successfully",
//        "user": { "_id": "...", "firstName": "...", "lastName": "...", "email": "...", "role": "participant" }
//      }
//
// 2. POST /api/auth/login
//    - Logs in a user.
//    - Request body: { email, password }
//    - Response:
//      {
//        "success": true,
//        "token": "JWT_TOKEN",
//        "user": { "_id": "...", "firstName": "...", "lastName": "...", "email": "...", "role": "instructor" }
//      }
//
// 3. GET /api/users/me
//    - Gets the current authenticated user's profile.
//    - Headers: Authorization: Bearer <token>
//    - Response:
//      {
//        "success": true,
//        "user": { "_id": "...", "firstName": "...", "lastName": "...", "email": "...", "role": "participant" }
//      }
//
// 4. GET /api/groups
//    - Lists all groups (with pagination, filtering, and search).
//    - Query params: page, limit, search, yoga_style, difficulty_level, is_active, location
//    - Response:
//      {
//        "success": true,
//        "data": {
//          "groups": [
//            {
//              "_id": "...",
//              "group_name": "Morning Vinyasa Flow",
//              "description": "...",
//              "instructor_id": { "_id": "...", "firstName": "...", "lastName": "...", "email": "..." },
//              "location": "...",
//              "timings_text": "...",
//              "yoga_style": "...",
//              "difficulty_level": "...",
//              ...
//            },
//            ...
//          ],
//          "pagination": { "current": 1, "pages": 2, "total": 12 }
//        }
//      }
//
// 5. POST /api/groups
//    - Creates a new group (instructor only).
//    - Request body: { group_name, location, location_text, latitude, longitude, timings_text, description, yoga_style, difficulty_level, session_duration, price_per_session, max_participants }
//    - Response:
//      {
//        "success": true,
//        "group": {
//          "_id": "...",
//          "group_name": "...",
//          "description": "...",
//          "instructor_id": { "_id": "...", "firstName": "...", "lastName": "..." },
//          ...
//        }
//      }
//
// 6. GET /api/groups/:groupId/members
//    - Lists members of a group.
//    - Response:
//      {
//        "success": true,
//        "members": [
//          { "_id": "...", "firstName": "...", "lastName": "...", "email": "...", "role": "participant" },
//          ...
//        ]
//      }
//
// 7. POST /api/groups/:groupId/members
//    - Adds a participant to a group (instructor only).
//    - Request body: { userId }
//    - Response:
//      {
//        "success": true,
//        "message": "Participant added to group"
//      }
//
// 8. GET /api/attendance/:groupId
//    - Gets attendance records for a group.
//    - Response:
//      {
//        "success": true,
//        "attendance": [
//          { "_id": "...", "user": { "_id": "...", "firstName": "...", "lastName": "..." }, "date": "2024-06-10", "status": "present" },
//          ...
//        ]
//      }
//
// 9. POST /api/attendance/mark
//    - Marks attendance for a session using QR code.
//    - Request body: { token }
//    - Response:
//      {
//        "success": true,
//        "message": "Attendance marked successfully"
//      }
//
// 10. GET /api/qr/:groupId/today
//     - Gets today's QR code for a group (instructor only).
//     - Response:
//       {
//         "success": true,
//         "qrCode": {
//           "_id": "...",
//           "token": "...",
//           "expires_at": "2024-06-10T09:30:00.000Z",
//           "session_start_time": "2024-06-10T08:00:00.000Z",
//           "session_end_time": "2024-06-10T09:00:00.000Z"
//         }
//       }
//
// 11. GET /api/users
//     - Lists all users (admin/instructor only).
//     - Response:
//       {
//         "success": true,
//         "users": [
//           { "_id": "...", "firstName": "...", "lastName": "...", "email": "...", "role": "participant" },
//           ...
//         ]
//       }
//
// For more details, refer to the API documentation or route files.

/*
api_doc = """Updated List of Available APIs and Sample Responses:

1. POST /api/auth/register
   - Registers a new user (instructor or participant).
   - Request body: { firstName, lastName, email, password, role }
   - Response:
     {
       "success": true,
       "message": "User registered successfully",
       "user": { "_id": "...", "firstName": "...", "lastName": "...", "email": "...", "role": "participant" }
     }

2. POST /api/auth/login
   - Logs in a user.
   - Request body: { email, password }
   - Response:
     {
       "success": true,
       "token": "JWT_TOKEN",
       "user": { "_id": "...", "firstName": "...", "lastName": "...", "email": "...", "role": "instructor" }
     }

3. GET /api/users/me
   - Gets the current authenticated user's profile.
   - Headers: Authorization: Bearer <token>
   - Response:
     {
       "success": true,
       "user": { "_id": "...", "firstName": "...", "lastName": "...", "email": "...", "role": "participant" }
     }

4. GET /api/groups
   - Lists all groups (with pagination, filtering, and search).
   - Query params: page, limit, search, yoga_style, difficulty_level, is_active, location
   - Response:
     {
       "success": true,
       "data": {
         "groups": [
           {
             "_id": "...",
             "group_name": "Morning Vinyasa Flow",
             "description": "...",
             "instructor_id": { "_id": "...", "firstName": "...", "lastName": "...", "email": "..." },
             "location": "...",
             "timings_text": "...",
             "yoga_style": "...",
             "difficulty_level": "..."
           },
           ...
         ],
         "pagination": { "current": 1, "pages": 2, "total": 12 }
       }
     }

5. POST /api/groups
   - Creates a new group (instructor only).
   - Request body: { group_name, location, location_text, latitude, longitude, timings_text, description, yoga_style, difficulty_level, session_duration, price_per_session, max_participants }
   - Response:
     {
       "success": true,
       "group": {
         "_id": "...",
         "group_name": "...",
         "description": "...",
         "instructor_id": { "_id": "...", "firstName": "...", "lastName": "..." }
       }
     }

6. GET /api/groups/:groupId/members
   - Lists members of a group.
   - Response:
     {
       "success": true,
       "members": [
         { "_id": "...", "firstName": "...", "lastName": "...", "email": "...", "role": "participant" },
         ...
       ]
     }

7. POST /api/groups/:groupId/members
   - Adds a participant to a group (instructor only).
   - Request body: { userId }
   - Response:
     {
       "success": true,
       "message": "Participant added to group"
     }

8. GET /api/attendance/:groupId
   - Gets attendance records for a group.
   - Response:
     {
       "success": true,
       "attendance": [
         { "_id": "...", "user": { "_id": "...", "firstName": "...", "lastName": "..." }, "date": "2024-06-10", "status": "present" },
         ...
       ]
     }

9. POST /api/attendance/mark
   - Marks attendance for a session using QR code.
   - Request body: { token }
   - Response:
     {
       "success": true,
       "message": "Attendance marked successfully"
     }

10. GET /api/qr/:groupId/today
    - Gets today's QR code for a group (instructor only).
    - Response:
      {
        "success": true,
        "qrCode": {
          "_id": "...",
          "token": "...",
          "expires_at": "2024-06-10T09:30:00.000Z",
          "session_start_time": "2024-06-10T08:00:00.000Z",
          "session_end_time": "2024-06-10T09:00:00.000Z"
        }
      }

11. GET /api/users
    - Lists all users (admin/instructor only).
    - Response:
      {
        "success": true,
        "users": [
          { "_id": "...", "firstName": "...", "lastName": "...", "email": "...", "role": "participant" },
          ...
        ]
      }
"""
*/
