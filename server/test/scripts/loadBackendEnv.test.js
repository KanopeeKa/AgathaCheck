import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { describe, expect, it } from '@jest/globals';

import { resolveBackendEnvPath } from '../../scripts/lib/loadBackendEnv.js';

const serverRoot = path.join(path.dirname(fileURLToPath(import.meta.url)), '../..');

describe('loadBackendEnv', () => {
  it('resolveBackendEnvPath points at server/.env', () => {
    const envPath = resolveBackendEnvPath();
    expect(envPath).toBe(path.join(serverRoot, '.env'));
  });

  it('ops scripts call loadBackendEnv before createAppPool', () => {
    for (const rel of [
      'scripts/ops/sql_readonly.js',
      'scripts/care/repair_tz_shift.js',
    ]) {
      const text = readFileSync(path.join(serverRoot, rel), 'utf8');
      expect(text).toMatch(/import \{ loadBackendEnv \}/);
      expect(text).toMatch(/loadBackendEnv\(\)/);
      const loadIdx = text.indexOf('loadBackendEnv()');
      const poolIdx = text.indexOf('createAppPool()');
      expect(loadIdx).toBeGreaterThan(-1);
      expect(poolIdx).toBeGreaterThan(loadIdx);
    }
  });
});
