// backend/scripts/setup.js
const fs = require('fs');
const path = require('path');

console.log('🚀 Setting up Yoga App Backend...\n');

// Check if .env file exists
const envPath = path.join(__dirname, '..', '.env');
const envExamplePath = path.join(__dirname, '..', '.env.example');

if (!fs.existsSync(envPath)) {
  console.log('📝 Creating .env file...');
  
  if (fs.existsSync(envExamplePath)) {
    // Copy from env.example
    const envContent = fs.readFileSync(envExamplePath, 'utf8');
    fs.writeFileSync(envPath, envContent);
    console.log('✅ .env file created from .env.example');
  } else {
    // Create basic .env file
    const basicEnv = `# Database Configuration
# Preferred: DATABASE_URL=postgresql://user:password@host:5432/dbname
PGHOST=localhost
PGPORT=5432
PGDATABASE=yoga_app
PGUSER=postgres
PGPASSWORD=postgres

# Database bootstrap
DB_SYNC=true

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
console.log('1. Ensure PostgreSQL is running and reachable');
console.log('2. Update DATABASE_URL (or PGHOST/PGPORT/PGDATABASE/PGUSER/PGPASSWORD) in .env');
console.log('3. Run: npm run dev');
console.log('4. Optional: npm run seed (populate sample data)');

console.log('\n🔧 PostgreSQL Setup Options:');
console.log('Option A - Local PostgreSQL:');
console.log('  - Install PostgreSQL');
console.log('  - Create database: yoga_app');
console.log('  - Keep PGHOST=localhost PGPORT=5432');

console.log('\nOption B - Managed Postgres (Cloud):');
console.log('  - Create a Postgres instance (Render/Railway/Supabase/AWS RDS, etc.)');
console.log('  - Copy connection string into DATABASE_URL');
console.log('  - If provider requires SSL, set NODE_ENV=production');

console.log('\n✨ Setup complete!');
