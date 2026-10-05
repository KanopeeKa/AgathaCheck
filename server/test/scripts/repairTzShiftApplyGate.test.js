import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const serverRoot = path.join(path.dirname(fileURLToPath(import.meta.url)), '../..');
const script = path.join(serverRoot, 'scripts/care/repair_tz_shift.js');

describe('repair_tz_shift.js apply gate', () => {
  it('exits before DB when --apply is refused on UAT', () => {
    const r = spawnSync(
      process.execPath,
      [script, '--apply', '--as-of-date=2026-10-05'],
      {
        cwd: serverRoot,
        env: { ...process.env, APP_ENV: 'uat' },
        encoding: 'utf8',
      },
    );
    expect(r.status).not.toBe(0);
    expect(r.stderr).toMatch(/Refusing repair_tz_shift --apply on UAT/);
  });
});
