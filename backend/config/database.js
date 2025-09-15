const mongoose = require('mongoose');
require('dotenv').config();

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

module.exports = connectDB;
