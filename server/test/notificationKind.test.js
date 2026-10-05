import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import {
  defaultKindForType,
  normaliseKind,
  normalisePriority,
  NOTIFICATION_KIND_CARE,
  NOTIFICATION_PRIORITY_NORMAL,
  NOTIFICATION_PRIORITY_URGENT,
  NOTIFICATION_TYPE_PENDING_FOSTER_PLACEMENT_RECEIVED,
  NOTIFICATION_TYPE_SHARE_INVITE_RECEIVED,
  NOTIFICATION_TYPE_SHARE_LINK_FOLLOWED,
  NOTIFICATION_KIND_ADMINISTRATIVE,
  NOTIFICATION_KIND_RELATIONSHIP,
} from '../lib/notificationKind.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..', '..');

describe('notificationKind', () => {
  it('maps every existing type to care kind by default', () => {
    for (const type of [
      'general',
      'due_soon',
      'overdue',
      'reminder',
      'completed',
      'health',
    ]) {
      expect(defaultKindForType(type)).toBe(NOTIFICATION_KIND_CARE);
    }
  });

  it('maps pending foster inbox types to administrative kind', () => {
    expect(defaultKindForType(NOTIFICATION_TYPE_PENDING_FOSTER_PLACEMENT_RECEIVED))
      .toBe(NOTIFICATION_KIND_ADMINISTRATIVE);
  });

  it('maps relationship share types to relationship kind', () => {
    expect(defaultKindForType(NOTIFICATION_TYPE_SHARE_INVITE_RECEIVED))
      .toBe(NOTIFICATION_KIND_RELATIONSHIP);
    expect(defaultKindForType(NOTIFICATION_TYPE_SHARE_LINK_FOLLOWED))
      .toBe(NOTIFICATION_KIND_RELATIONSHIP);
  });

  it('normalises invalid kind and priority wire values', () => {
    expect(normaliseKind(null)).toBe(NOTIFICATION_KIND_CARE);
    expect(normaliseKind('administrative')).toBe('administrative');
    expect(normaliseKind('relationship')).toBe('relationship');
    expect(normaliseKind('suggestion')).toBe('suggestion');
    expect(normaliseKind('account')).toBe('account');
    expect(normaliseKind('bogus')).toBe(NOTIFICATION_KIND_CARE);
    expect(normalisePriority('urgent')).toBe(NOTIFICATION_PRIORITY_URGENT);
    expect(normalisePriority('bogus')).toBe(NOTIFICATION_PRIORITY_NORMAL);
  });
});

describe('033_notification_kind_priority_resolved migration', () => {
  it('up and down SQL files exist and reference expected columns', () => {
    const up = fs.readFileSync(
      path.join(repoRoot, 'db/migrations/033_notification_kind_priority_resolved.sql'),
      'utf8'
    );
    const down = fs.readFileSync(
      path.join(repoRoot, 'db/migrations/033_notification_kind_priority_resolved_down.sql'),
      'utf8'
    );
    expect(up).toMatch(/ADD COLUMN IF NOT EXISTS kind/);
    expect(up).toMatch(/ADD COLUMN IF NOT EXISTS priority/);
    expect(up).toMatch(/ADD COLUMN IF NOT EXISTS resolved_at/);
    expect(down).toMatch(/DROP COLUMN IF EXISTS kind/);
    expect(down).toMatch(/DROP COLUMN IF EXISTS priority/);
    expect(down).toMatch(/DROP COLUMN IF EXISTS resolved_at/);
  });
});
