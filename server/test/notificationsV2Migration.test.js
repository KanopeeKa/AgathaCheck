import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..', '..');

describe('094_notifications_v2_pr1 migration', () => {
  it('archives due reminders and expands kind constraint', () => {
    const up = fs.readFileSync(
      path.join(repoRoot, 'db/migrations/094_notifications_v2_pr1.sql'),
      'utf8',
    );
    expect(up).toMatch(/ADD COLUMN IF NOT EXISTS archived_at/);
    expect(up).toMatch(/kind IN \('care', 'administrative', 'relationship', 'suggestion', 'account'\)/);
    expect(up).toMatch(/type IN \('overdue', 'due_soon'\)/);
    expect(up).not.toMatch(/SET kind = 'care'/);
  });

  it('down migration drops archived_at and restores two-kind check', () => {
    const down = fs.readFileSync(
      path.join(repoRoot, 'db/migrations/094_notifications_v2_pr1_down.sql'),
      'utf8',
    );
    expect(down).toMatch(/DROP COLUMN IF EXISTS archived_at/);
    expect(down).toMatch(/CHECK \(kind IN \('care', 'administrative'\)\)/);
  });
});
