// backend/config/database.js
const mongoose = require('mongoose');
require('dotenv').config();

const connectDB = async () => {
  // 1. Sirf environment variable se URI lega.
  const mongoURI = process.env.MONGODB_URI;

  // 2. Agar URI nahi mila, toh server start hi nahi hoga.
  if (!mongoURI) {
    console.error('FATAL ERROR: MONGODB_URI is not defined in the .env file.');
    process.exit(1); // Failure code ke saath exit
  }

  try {
    // 3. Production database (Atlas) se connect karega.
    const conn = await mongoose.connect(mongoURI);
    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    // 4. Agar connection fail hua, toh error dekar exit ho jayega.
    console.error('Database connection failed:', error.message);
    process.exit(1); // Failure code ke saath exit
  }
};

module.exports = connectDB;