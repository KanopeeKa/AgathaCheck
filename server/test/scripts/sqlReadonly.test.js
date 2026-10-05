import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const serverRoot = path.join(path.dirname(fileURLToPath(import.meta.url)), '../..');
const script = path.join(serverRoot, 'scripts/ops/sql_readonly.js');

function shellWithoutPgEnv() {
  const env = { ...process.env };
  for (const key of Object.keys(env)) {
    if (key.startsWith('PG') || key === 'DATABASE_URL') delete env[key];
  }
  return env;
}

describe('sql_readonly.js', () => {
  it('loads server/.env when PG variables are unset in the shell', () => {
    const envFile = path.join(serverRoot, '.env');
    if (!existsSync(envFile)) return;

    const r = spawnSync(process.execPath, [script], {
      input: 'SELECT 1 AS ok;',
      cwd: serverRoot,
      env: shellWithoutPgEnv(),
      encoding: 'utf8',
    });
    expect(r.status).toBe(0);
    expect(r.stdout).toMatch(/"ok"\s*:\s*1/);
  });

  it('rejects write statements on stdin', () => {
    const r = spawnSync(process.execPath, [script], {
      input: 'DELETE FROM users;',
      cwd: serverRoot,
      encoding: 'utf8',
    });
    expect(r.status).not.toBe(0);
    expect(r.stderr).toMatch(/not allowed/i);
  });
});
