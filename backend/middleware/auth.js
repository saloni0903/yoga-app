const jwt = require('jsonwebtoken');
const User = require('../model/User');

module.exports = async function(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader) {
    return res.status(401).json({ success: false, message: 'No token provided' });
  }

  // Make sure the header is in the correct "Bearer <token>" format
  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    return res.status(401).json({ success: false, message: 'Token format is "Bearer <token>"' });
  }
  const token = parts[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // ✅ The Fix: Use decoded.userId to find the user
    req.user = await User.findById(decoded.userId).select('-password');

    if (!req.user) {
      return res.status(401).json({ success: false, message: 'User not found' });
    }
    next();
  } catch (err) {
    // Log the actual error to your server console for better debugging
    console.error('JWT Verification Error:', err.message);
    res.status(401).json({ success: false, message: 'Invalid token' });
  }
};