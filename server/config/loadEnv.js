import dotenv from 'dotenv';
import fs from 'node:fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Load .env before any module reads process.env at import time (e.g. mail.js).
// Resolve from this file so Passenger/cPanel spawns work when process.cwd() is not backend/.
const serverRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const serverEnvPath = path.join(serverRoot, '.env');
const cwdEnvPath = path.join(process.cwd(), '.env');

const hostPresetKeys = ['JWT_SECRET', 'SESSION_SECRET', 'PGHOST', 'PGDATABASE', 'NODE_ENV'];
const presetByHost = hostPresetKeys.filter((key) => process.env[key] !== undefined);

const pathsToLoad = [serverEnvPath];
if (path.resolve(cwdEnvPath) !== path.resolve(serverEnvPath)) {
  pathsToLoad.push(cwdEnvPath);
}

const dotenvResult = dotenv.config({ path: pathsToLoad, quiet: true });
const loadedKeyCount = dotenvResult.parsed ? Object.keys(dotenvResult.parsed).length : 0;

const serverEnvExists = fs.existsSync(serverEnvPath);
console.log(
  `[env] serverEnv=${serverEnvPath} exists=${serverEnvExists} keysFromDotenv=${loadedKeyCount} cwd=${process.cwd()} presetByHost=${presetByHost.join(',') || 'none'}`,
);
