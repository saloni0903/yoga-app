// backend/middleware/auth.js
const jwt = require('jsonwebtoken');
const User = require('../model/User');

// Ensure JWT_SECRET is read correctly (fallback only for non-production)
const JWT_SECRET_KEY = process.env.NODE_ENV === 'production' 
    ? process.env.JWT_SECRET 
    : (process.env.JWT_SECRET || 'your-secret-key'); 

// Only warn in non-production environments
if (process.env.NODE_ENV !== 'production' && JWT_SECRET_KEY === 'your-secret-key') {
  console.warn('****************************************************************');
  console.warn('** WARNING: Using default JWT secret. Set JWT_SECRET in .env! **');
  console.warn('****************************************************************');
}

module.exports = async function(req, res, next) {
    let token = null;

    // 1. Check for the specific httpOnly cookie named 'adminToken' (used by web admin)
    if (req.cookies && req.cookies.adminToken) {
        token = req.cookies.adminToken;
        console.log('[Auth Middleware] Found token in adminToken cookie.'); // DEBUG LOG
    } 
    // 2. Fallback: Check Authorization header (used by mobile app)
    else {
        const authHeader = req.headers['authorization'];
        if (authHeader && authHeader.startsWith('Bearer ')) {
            token = authHeader.split(' ')[1];
            console.log('[Auth Middleware] Found token in Authorization header.'); // DEBUG LOG
        }
    }

    // 3. If no token found by either method
    if (!token) {
        console.log('[Auth Middleware] No token found in cookie or header.'); // DEBUG LOG
        return res.status(401).json({ success: false, message: 'Authentication required. No token provided.' });
    }

    // 4. Verify the token
    try {
        const decoded = jwt.verify(token, JWT_SECRET_KEY);
        console.log('[Auth Middleware] Token decoded:', decoded); // DEBUG LOG

        // Find user by ID from token payload
        req.user = await User.findByPk(decoded.userId);

        if (!req.user) {
            console.log('[Auth Middleware] User not found for decoded ID:', decoded.userId); // DEBUG LOG
            // Optional: Clear potentially invalid cookie if user not found?
            // res.clearCookie('adminToken'); 
            return res.status(401).json({ success: false, message: 'User associated with token not found.' });
        }
        
        console.log('[Auth Middleware] User found:', req.user.email, req.user.role); // DEBUG LOG
        next(); // Authentication successful, proceed to next middleware (e.g., isAdmin) or route handler

    } catch (err) {
        console.error('[Auth Middleware] JWT Verification Error:', err.message); // DEBUG LOG

        // Clear potentially invalid/expired cookie on error
        res.clearCookie('adminToken', { httpOnly: true, secure: process.env.NODE_ENV === 'production', sameSite: 'strict' });

        if (err.name === 'JsonWebTokenError') {
            return res.status(401).json({ success: false, message: 'Invalid token signature.' });
        }
        if (err.name === 'TokenExpiredError') {
            return res.status(401).json({ success: false, message: 'Your session has expired. Please log in again.' });
        }
        // Generic invalid token for other errors
        res.status(401).json({ success: false, message: 'Invalid token.' });
    }
};