# Yoga App Backend

A comprehensive backend API for a yoga group management and attendance tracking system.

## Features

- **User Management**: Registration, authentication, and profile management for instructors and participants
- **Group Management**: Create and manage yoga groups with location, timing, and instructor details
- **Membership System**: Join/leave groups with payment tracking
- **Attendance Tracking**: QR code-based attendance marking with location verification
- **QR Code System**: Generate and manage session QR codes with expiration and usage limits
- **Statistics**: Attendance reports and analytics

## Database Schema

The application uses PostgreSQL (via Sequelize) with the following main tables:

- **users**: Instructor and participant profiles
- **groups**: Yoga group information with location and timing details
- **group_members**: Membership relationships between users and groups
- **attendance**: Session attendance records with QR code tracking
- **session_qr_codes**: QR codes for session attendance marking

## Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```

3. Set up environment variables:
   ```bash
   cp .env.example .env
   ```
   Edit `.env` with your configuration.

4. Ensure PostgreSQL is running and a database exists.
   - Local default port is usually `5432`.
   - Create a database (example): `yoga_app`

5. Seed the database with sample data:
   ```bash
   npm run seed
   ```

6. Start the development server:
   ```bash
   npm run dev
   ```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/profile` - Get current user profile

### Users
- `GET /api/users` - Get all users (with pagination and filters)
- `GET /api/users/:id` - Get user by ID
- `PUT /api/users/:id` - Update user profile
- `DELETE /api/users/:id` - Delete user

### Groups
- `GET /api/groups` - Get all groups (with pagination and filters)
- `GET /api/groups/:id` - Get group by ID
- `POST /api/groups` - Create new group
- `PUT /api/groups/:id` - Update group
- `DELETE /api/groups/:id` - Delete group
- `GET /api/groups/:id/members` - Get group members
- `POST /api/groups/:id/join` - Join group
- `DELETE /api/groups/:id/leave` - Leave group

### Attendance
- `POST /api/attendance/mark` - Mark attendance
- `GET /api/attendance/session/:group_id/:session_date` - Get session attendance
- `GET /api/attendance/user/:user_id` - Get user attendance history
- `GET /api/attendance/stats/:group_id` - Get attendance statistics
- `PUT /api/attendance/:id` - Update attendance record
- `DELETE /api/attendance/:id` - Delete attendance record

### QR Codes
- `POST /api/qr/generate` - Generate QR code for session
- `POST /api/qr/scan` - Scan QR code and mark attendance
- `GET /api/qr/:token` - Get QR code details
- `GET /api/qr/group/:group_id` - Get active QR codes for group
- `PUT /api/qr/:id/deactivate` - Deactivate QR code
- `GET /api/qr/:id/stats` - Get QR code usage statistics

## Sample Data

The seed script creates:
- 2 instructors
- 10 participants
- 3 yoga groups
- Sample memberships and attendance records
- QR codes for today's sessions

### Test Credentials
- **Instructor 1**: sarah.yoga@example.com / password123
- **Instructor 2**: mike.zen@example.com / password123
- **Participants**: participant1@example.com to participant10@example.com / password123

## Environment Variables

- `DATABASE_URL`: Postgres connection string (recommended)
- `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`: Discrete Postgres settings (alternative to `DATABASE_URL`)
- `DB_SYNC`: If not `false`, auto-sync schema at startup (use migrations in production)
- `PORT`: Server port (default: 3000)
- `NODE_ENV`: Environment (development/production)
- `JWT_SECRET`: Secret key for JWT tokens
- `APP_URL`: Application URL for QR code generation

## Technologies Used

- **Node.js** - Runtime environment
- **Express.js** - Web framework
- **PostgreSQL** - Database
- **Sequelize** - ORM
- **JWT** - Authentication
- **bcryptjs** - Password hashing
- **CORS** - Cross-origin resource sharing

## Development

- `npm start` - Start production server
- `npm run dev` - Start development server with nodemon
- `npm run seed` - Seed database with sample data

## License

ISC
