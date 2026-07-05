import dotenv from 'dotenv';

// Load .env before any module reads process.env at import time (e.g. mail.js).
dotenv.config();
