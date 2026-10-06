import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..', '..');

describe('095_notifications_v2_suggestion_fields migration', () => {
  it('adds suggestion inbox columns and partial unique index', () => {
    const up = fs.readFileSync(
      path.join(repoRoot, 'db/migrations/095_notifications_v2_suggestion_fields.sql'),
      'utf8',
    );
    expect(up).toMatch(/suggestion_dedupe_key/);
    expect(up).toMatch(/suggestion_state/);
    expect(up).toMatch(/suggestion_payload/);
    expect(up).toMatch(/idx_notifications_suggestion_dedupe_active/);
  });
});
