// backend/index.js

// 1. Import Express
const express = require('express');

// 2. Create an instance of the Express app
const app = express();

// 3. Define the port the server will run on
const port = 3000;

// 4. Create a basic route
// This handles GET requests to the root URL ('/')
app.get('/', (req, res) => {
  res.json({ message: 'Hello from the backend server!' });
});

// 5. Start the server and listen for incoming connections
app.listen(port, () => {
  console.log(`Server is running at http://localhost:${port}`);
});
