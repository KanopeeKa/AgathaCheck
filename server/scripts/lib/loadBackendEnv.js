/**
 * Load `server/.env` for CLI scripts (cron/SSH do not inherit cPanel app env).
 */
import path from 'path';
import { fileURLToPath } from 'url';

import dotenv from 'dotenv';

const scriptsLibDir = path.dirname(fileURLToPath(import.meta.url));

/** @returns {string} Absolute path to `server/.env`. */
export function resolveBackendEnvPath() {
  return path.resolve(scriptsLibDir, '../../.env');
}

/** Load backend `.env` then process cwd `.env` (same order as care_tick.js). */
export function loadBackendEnv() {
  dotenv.config({ path: resolveBackendEnvPath() });
  dotenv.config();
}
