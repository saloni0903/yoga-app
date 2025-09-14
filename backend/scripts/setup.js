const fs = require('fs');
const path = require('path');

console.log('🚀 Setting up Yoga App Backend...\n');

// Check if .env file exists
const envPath = path.join(__dirname, '..', '.env');
const envExamplePath = path.join(__dirname, '..', 'env.example');

if (!fs.existsSync(envPath)) {
  console.log('📝 Creating .env file...');
  
  if (fs.existsSync(envExamplePath)) {
    // Copy from env.example
    const envContent = fs.readFileSync(envExamplePath, 'utf8');
    fs.writeFileSync(envPath, envContent);
    console.log('✅ .env file created from env.example');
  } else {
    // Create basic .env file
    const basicEnv = `# Database Configuration
MONGODB_URI=mongodb://localhost:27017/yoga_app

# Server Configuration
PORT=3000
NODE_ENV=development

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# Application Configuration
APP_URL=http://localhost:3000
`;
    fs.writeFileSync(envPath, basicEnv);
    console.log('✅ Basic .env file created');
  }
} else {
  console.log('✅ .env file already exists');
}

console.log('\n📋 Next steps:');
console.log('1. Make sure MongoDB is running locally, OR');
console.log('2. Update MONGODB_URI in .env file with your MongoDB Atlas connection string');
console.log('3. Run: npm run dev');
console.log('4. Run: npm run seed (to populate with sample data)');

console.log('\n🔧 MongoDB Setup Options:');
console.log('Option A - Local MongoDB:');
console.log('  - Install MongoDB Community Edition');
console.log('  - Start MongoDB service');
console.log('  - Keep MONGODB_URI=mongodb://localhost:27017/yoga_app');

console.log('\nOption B - MongoDB Atlas (Cloud):');
console.log('  - Create free account at https://cloud.mongodb.com');
console.log('  - Create a cluster');
console.log('  - Get connection string and update MONGODB_URI in .env');

console.log('\n✨ Setup complete!');
