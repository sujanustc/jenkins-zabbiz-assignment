const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Welcome to the Jenkins CI/CD Automated Node.js Web Application!',
    timestamp: new Date()
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'UP',
    uptime: process.uptime()
  });
});

const server = app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

module.exports = { app, server };
