const mongoose = require('mongoose');
const User = require('../model/User');
const connectDB = require('../config/database');
require('dotenv').config();

const createAdmin = async () => {
  await connectDB();

  const adminEmail = 'admin@yoga.gov.in'; 
  const adminPassword = 'AdminPassword123!'; 

  try {
    const existingAdmin = await User.findOne({ email: adminEmail });
    if (existingAdmin) {
      console.log('Admin user already exists.');
      process.exit();
    }

    const admin = new User({
      firstName: 'Aayush',
      lastName: 'Admin',
      email: adminEmail,
      password: adminPassword, 
      role: 'admin',
      status: 'approved',
      location: 'Indore, MP', 
    });

    await admin.save();
    console.log(' Aayush admin account created successfully!');
    console.log(`   Email: ${adminEmail}`);
    console.log(`   Password: ${adminPassword}`);
  } catch (error) {
    console.error('Error creating admin user:', error);
  } finally {
    mongoose.disconnect();
  }
};

createAdmin();