import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '../..');
const script = path.join(root, 'scripts/ops/sql_readonly.js');

describe('sql_readonly.js', () => {
  it('rejects write statements on stdin', () => {
    const r = spawnSync(process.execPath, [script], {
      input: 'DELETE FROM users;',
      cwd: root,
      encoding: 'utf8',
    });
    expect(r.status).not.toBe(0);
    expect(r.stderr).toMatch(/not allowed/i);
  });
});
