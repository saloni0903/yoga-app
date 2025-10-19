// backend/app.js
const cors = require('cors');
const dotenv = require('dotenv');
const express = require('express');
const cookieParser = require('cookie-parser');
const connectDB = require('./config/database');
const initializeScheduler = require('./services/notificationScheduler');

// Load environment variables
dotenv.config();
if (
  process.env.NODE_ENV === 'production' &&
  (!process.env.JWT_SECRET || process.env.JWT_SECRET === 'your-secret-key')
) {
  console.error(
    'FATAL ERROR: JWT_SECRET is not defined or is insecure in production. Application cannot start.'
  );
  process.exit(1);
}

// Connect to database
connectDB();
initializeScheduler();

const app = express();

// cors config:
const whitelist = ['https://aayush-dashboard.onrender.com']; // Production origins ONLY
const corsOptions = {
    origin: function (origin, callback) {
        // Allow requests from the whitelist, requests with no origin (like mobile apps or Postman),
        // and any localhost origin when NOT in production.
        if (whitelist.indexOf(origin) !== -1 || !origin || (process.env.NODE_ENV !== 'production' && origin.startsWith('http://localhost:'))) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
};
app.use(cors(corsOptions));

// Middleware
app.use(cookieParser());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use('/api/schedule', require('./routes/schedule'));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

app.get('/', (req, res) => {
  res.json({ success: true, message: 'Yoga backend running!', environment: process.env.NODE_ENV || 'development' });
});

// API routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/groups', require('./routes/groups'));
app.use('/api/attendance', require('./routes/attendance'));
app.use('/api/qr', require('./routes/qr'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/schedule', require('./routes/schedule'));

// 404 handler - catch all unmatched routes
app.use((req, res, next) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
    path: req.originalUrl
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
