// backend/config/database.js
const mongoose = require('mongoose');
require('dotenv').config();

const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGODB_URI;

    // We can remove the options object because modern Mongoose (v6+)
    // handles these settings automatically from the URI.
    // This also removes the source of the 'sslValidate' error.
    const conn = await mongoose.connect(mongoURI);

    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error('Atlas connection error:', error.message);

    // ▼▼▼ THIS IS THE KEY CHANGE ▼▼▼
    // Only attempt a local connection if the environment is NOT production.
    if (process.env.NODE_ENV !== 'production') {
      console.log('Trying fallback to local MongoDB for development...');
      
      try {
        const conn = await mongoose.connect('mongodb://localhost:27017/yoga_app');
        console.log(`✅ MongoDB Connected (Local Fallback): ${conn.connection.host}`);
      } catch (localError) {
        console.error('Local MongoDB connection also failed:', localError.message);
        process.exit(1);
      }
    } else {
      // If in production, do not try the fallback. Just exit.
      console.log('Production environment: Halting due to failed database connection.');
      process.exit(1);
    }
  }
};

module.exports = connectDB;