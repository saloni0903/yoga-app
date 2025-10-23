const jwt = require('jsonwebtoken');
const User = require('../model/User');

const JWT_SECRET_KEY = process.env.JWT_SECRET || 'your-secret-key';

// module.exports = async function(req, res, next) {
//   console.log('[isAdmin Middleware] Running check...');
  
//   // First, use your existing auth logic to verify the token and get the user
//   const authHeader = req.headers['authorization'];
//   if (!authHeader || !authHeader.startsWith('Bearer ')) {
//     return res.status(401).json({ success: false, message: 'Authorization required' });
//   }
//   const token = authHeader.split(' ')[1];

//   try {
//     const decoded = jwt.verify(token, JWT_SECRET_KEY);
//     const user = await User.findById(decoded.userId).select('-password');
//     if (!user) {
//       return res.status(401).json({ success: false, message: 'User not found' });
//     }

//     // ✅ ADMIN CHECK: Now, check if the authenticated user has the 'admin' role
//     if (user.role !== 'admin') {
//       return res.status(403).json({ success: false, message: 'Access denied. Admin privileges required.' });
//     }

//     // If they are an admin, attach the user object and proceed
//     req.user = user;
//     next();
//   } catch (err) {
//     res.status(401).json({ success: false, message: 'Invalid token.' });
//   }
// };

module.exports = async function(req, res, next) {
  console.log('[isAdmin Middleware] Running check...'); // <-- ADD LOG

  // Original Logic (assuming it was based on req.user from previous auth middleware)
  if (!req.user) {
    // This case should ideally not happen if 'auth' runs first and succeeds
    console.log('[isAdmin Middleware] FAILED: req.user is missing. Auth middleware likely did not run or failed.'); // <-- ADD LOG
    return res.status(401).json({ success: false, message: 'Authentication required (isAdmin check failed - no user).' });
  }

  console.log(`[isAdmin Middleware] User found: ${req.user.email}, Role: ${req.user.role}`); // <-- ADD LOG

  if (req.user.role !== 'admin') {
    console.log('[isAdmin Middleware] FAILED: User is not an admin.'); // <-- ADD LOG
    return res.status(403).json({ success: false, message: 'Access denied. Admin privileges required.' });
  }

  // If user exists and role is 'admin'
  console.log('[isAdmin Middleware] PASSED: User is admin.'); // <-- ADD LOG
  next(); // Proceed to the route handler

  /*
  // DELETE or comment out your previous logic that re-verified the token.
  // The 'auth' middleware ALREADY DOES THIS. isAdmin ONLY checks the role.
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    // ...
  }
  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET_KEY);
    const user = await User.findById(decoded.userId).select('-password');
    // ... redundant checks ...
    if (user.role !== 'admin') {
       // ...
    }
    req.user = user; // This should already be done by 'auth'
    next();
  } catch (err) {
    // ... redundant error handling ...
  }
  */
};