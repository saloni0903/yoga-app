const admin = require('firebase-admin');

// 1. Define the correct path based on the environment
const serviceAccountPath = process.env.NODE_ENV === 'production'
  ? '/etc/secrets/serviceAccountKey.json' // The path on Render
  : './serviceAccountKey.json';           // The path on your local computer

try {
  // 2. Require the file from the path we just defined
  const serviceAccount = require(serviceAccountPath);

  // 3. Initialize Firebase
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });

  console.log('✅ Firebase Admin SDK Initialized.');

} catch (error) {
  if (error.code === 'MODULE_NOT_FOUND') {
    console.error('---------------------------------------------------------------');
    console.error(`Error: Could not find service account key at ${serviceAccountPath}`);
    console.error('Make sure "serviceAccountKey.json" is in your backend folder.');
    console.error('---------------------------------------------------------------');
  } else {
    console.error('Firebase Admin SDK Initialization Error:', error);
  }
  // Exit if Firebase fails to initialize, as it's a critical service
  process.exit(1); 
}

module.exports = admin;