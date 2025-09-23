const jwt = require('jsonwebtoken');
const User = require('../model/User');

const JWT_SECRET_KEY = process.env.JWT_SECRET || 'your-secret-key';

module.exports = async function(req, res, next) {
  // First, use your existing auth logic to verify the token and get the user
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'Authorization required' });
  }
  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET_KEY);
    const user = await User.findById(decoded.userId).select('-password');
    if (!user) {
      return res.status(401).json({ success: false, message: 'User not found' });
    }

    // ✅ ADMIN CHECK: Now, check if the authenticated user has the 'admin' role
    if (user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Access denied. Admin privileges required.' });
    }

    // If they are an admin, attach the user object and proceed
    req.user = user;
    next();
  } catch (err) {
    res.status(401).json({ success: false, message: 'Invalid token.' });
  }
};