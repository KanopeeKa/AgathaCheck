#!/usr/bin/env node
/**
 * Grant or revoke users.is_support_staff (D-005). Tokens and profile never expose this flag.
 *
 * Usage:
 *   node server/scripts/support_staff.js grant --email user@example.com
 *   node server/scripts/support_staff.js revoke --email user@example.com
 */
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { createAppPool } from '../lib/db/createPool.js';
import { setSupportStaffFlagByEmail } from '../lib/support/staff/staffFlag.js';
import { loadBackendEnv } from './lib/loadBackendEnv.js';

const __filename = fileURLToPath(import.meta.url);

loadBackendEnv();

function parseEmail(argv) {
  const flagIdx = argv.indexOf('--email');
  if (flagIdx >= 0 && argv[flagIdx + 1]) {
    return argv[flagIdx + 1];
  }
  const eq = argv.find((a) => a.startsWith('--email='));
  if (eq) {
    return eq.slice('--email='.length);
  }
  return null;
}

function usage() {
  console.error('Usage: support_staff.js grant|revoke --email <address>');
}

async function main() {
  const command = process.argv[2];
  const email = parseEmail(process.argv);
  if (!command || !email || !['grant', 'revoke'].includes(command)) {
    usage();
    process.exit(1);
  }

  const isStaff = command === 'grant';
  const pool = createAppPool();
  try {
    const result = await setSupportStaffFlagByEmail(pool, email, isStaff);
    if (!result.ok) {
      if (result.reason === 'not_found') {
        console.error(`support_staff: no user found for ${email}`);
        process.exit(2);
      }
      console.error('support_staff: invalid email');
      process.exit(1);
    }
    const flag = result.user.is_support_staff ? 'granted' : 'revoked';
    console.log(
      `support_staff: ${flag} for ${result.user.email} (${result.user.id})`,
    );
  } finally {
    await pool.end();
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === __filename) {
  main().catch((err) => {
    console.error(`support_staff ERROR: ${err.message}`);
    process.exit(1);
  });
}
