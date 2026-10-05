import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Load .env before any module reads process.env at import time (e.g. mail.js).
// Resolve from this file so Passenger/cPanel spawns work when process.cwd() is not backend/.
const serverRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
dotenv.config({ path: path.join(serverRoot, '.env') });
dotenv.config({ path: path.join(process.cwd(), '.env') });
