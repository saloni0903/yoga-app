const jwt = require('jsonwebtoken');
const User = require('../model/User');

const JWT_SECRET_KEY = process.env.JWT_SECRET || 'your-secret-key';

if (JWT_SECRET_KEY === 'your-secret-key') {
  console.warn('...'); // Warning is fine here
}

module.exports = async function(req, res, next) {
  const token = req.cookies.token;
  if (!token) {
      return res.status(401).json({ success: false, message: 'Authentication required. No token provided.' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET_KEY);
    req.user = await User.findById(decoded.userId).select('-password');

    if (!req.user) {
      return res.status(401).json({ success: false, message: 'User not found' });
    }
    next();
  } catch (err) {
    console.error('JWT Verification Error:', err.message);
    if (err.name === 'JsonWebTokenError') {
        return res.status(401).json({ success: false, message: 'Invalid token signature.' });
    }
    if (err.name === 'TokenExpiredError') {
        return res.status(401).json({ success: false, message: 'Your session has expired. Please log in again.' });
    }
    res.status(401).json({ success: false, message: 'Invalid token.' });
  }
};