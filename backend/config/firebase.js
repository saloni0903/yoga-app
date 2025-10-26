// Example: config/firebase.js
const admin = require('firebase-admin');
const serviceAccount = require('/etc/secrets/serviceAccountKey.json'); // Use Render's secret file path

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

console.log('✅ Firebase Admin SDK Initialized.');
module.exports = admin;