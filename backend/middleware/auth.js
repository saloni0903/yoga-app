const jwt = require('jsonwebtoken');
const User = require('../model/User');

// ✅ The secret key is now defined in one place with a fallback.
const JWT_SECRET_KEY = process.env.JWT_SECRET || 'your-secret-key';

// Add a check to warn the developer if they are using the insecure default key.
if (JWT_SECRET_KEY === 'your-secret-key') {
  console.warn('****************************************************************');
  console.warn('** WARNING: Using default JWT secret. Please set JWT_SECRET in your .env file for production!');
  console.warn('****************************************************************');
}

module.exports = async function(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader) {
    return res.status(401).json({ success: false, message: 'No token provided' });
  }

  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    return res.status(401).json({ success: false, message: 'Token format is "Bearer <token>"' });
  }
  const token = parts[1];

  try {
    // ✅ FIX: Use the synchronized secret key for verification.
    const decoded = jwt.verify(token, JWT_SECRET_KEY);
    
    // Find the user based on the ID stored in the token.
    req.user = await User.findById(decoded.userId).select('-password');

    if (!req.user) {
      return res.status(401).json({ success: false, message: 'User not found' });
    }
    next();
  } catch (err) {
    console.error('JWT Verification Error:', err.message);
    // Provide a more specific error message back to the client.
    if (err.name === 'JsonWebTokenError') {
        return res.status(401).json({ success: false, message: 'Invalid token signature.' });
    }
    if (err.name === 'TokenExpiredError') {
        return res.status(401).json({ success: false, message: 'Your session has expired. Please log in again.' });
    }
    res.status(401).json({ success: false, message: 'Invalid token.' });
  }
};
