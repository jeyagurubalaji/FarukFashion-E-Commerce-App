require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const connectDB = require('./config/db');
const routes = require('./routes');

const app = express();
const PORT = process.env.PORT || 8080;

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (curl, mobile apps) and any localhost
      if (
        !origin ||
        origin.startsWith('http://localhost:') ||
        origin.startsWith('http://127.0.0.1:') ||
        origin === 'https://farukfashion-app.vercel.app' ||
        origin === 'https://farukfashion.vercel.app'
      ) {
        callback(null, true);
      } else {
        callback(null, true); // or callback(new Error('Not allowed by CORS')) in production
      }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Ensure Mongo is connected on each serverless invocation
app.use(async (req, res, next) => {
  try {
    await connectDB();
    next();
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message || 'Database connection failed',
    });
  }
});

app.use('/api', routes);

app.use((err, req, res, next) => {
  console.error(err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Something went wrong',
  });
});

if (require.main === module) {
  connectDB()
    .then(() => {
      app.listen(PORT, () => {
        console.log(`Faruk Fashion API → http://localhost:${PORT}/api`);
      });
    })
    .catch((e) => {
      console.error(e);
      process.exit(1);
    });
}

module.exports = app;