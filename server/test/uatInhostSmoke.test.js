import { describe, expect, it } from '@jest/globals';

import { parseMigrationStatusOutput } from '../scripts/uat-inhost-smoke-lib.js';

describe('uat in-host smoke lib', () => {
  describe('parseMigrationStatusOutput', () => {
    it('accepts zero pending', () => {
      const out = `Migration status:\n  [applied] 001_init.sql\n3 applied, 0 pending.`;
      expect(parseMigrationStatusOutput(out)).toEqual({ pending: 0, ok: true });
    });

    it('rejects pending migrations', () => {
      const out = `  [PENDING] 099_new.sql\n3 applied, 1 pending.`;
      expect(parseMigrationStatusOutput(out)).toEqual({ pending: 1, ok: false });
    });
  });
});
