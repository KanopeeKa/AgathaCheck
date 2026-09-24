import { describe, expect, it } from '@jest/globals';

import { validateReschedule } from '../../lib/care/schedule/validateReschedule.js';

describe('validateReschedule', () => {
  const today = '2026-09-24';
  const entry = {
    frequency: 'weekly',
    frequency_interval: 1,
    recurrence_anchor: 'from_completion',
    care_family: 'medication',
    care_source: 'guardian_defined',
  };

  it('rejects past dates and no-op moves', () => {
    expect(
      validateReschedule({
        entry,
        occurrenceScheduledDate: '2026-09-20',
        newDate: '2026-09-23',
        todayIso: today,
      }).ok,
    ).toBe(false);
    expect(
      validateReschedule({
        entry,
        occurrenceScheduledDate: '2026-09-25',
        newDate: '2026-09-25',
        todayIso: today,
      }).ok,
    ).toBe(false);
  });

  it('rejects moves on or after the next hop and before last closed', () => {
    expect(
      validateReschedule({
        entry,
        occurrenceScheduledDate: '2026-09-25',
        newDate: '2026-10-02',
        todayIso: today,
      }).ok,
    ).toBe(false);
    expect(
      validateReschedule({
        entry,
        occurrenceScheduledDate: '2026-09-25',
        newDate: '2026-09-20',
        todayIso: today,
        lastClosedDate: '2026-09-20',
      }).ok,
    ).toBe(false);
  });

  it('returns warnings for interval change and earlier_only later move', () => {
    const earlierOnly = {
      ...entry,
      care_family: 'vaccination',
    };
    const later = validateReschedule({
      entry: earlierOnly,
      occurrenceScheduledDate: '2026-09-25',
      newDate: '2026-09-27',
      todayIso: today,
      lastClosedDate: '2026-09-01',
    });
    expect(later.ok).toBe(true);
    expect(later.warnings.some((w) => w.code === 'earlier_only_later_move')).toBe(true);

    const interval = validateReschedule({
      entry,
      occurrenceScheduledDate: '2026-09-25',
      newDate: '2026-09-27',
      todayIso: today,
      lastClosedDate: '2026-09-01',
    });
    expect(interval.ok).toBe(true);
    expect(interval.warnings.some((w) => w.code === 'interval_changed')).toBe(true);
  });

  it('allows once-frequency moves with only past and no-op guards', () => {
    const once = { frequency: 'once' };
    const ok = validateReschedule({
      entry: once,
      occurrenceScheduledDate: '2026-10-01',
      newDate: '2026-10-05',
      todayIso: today,
    });
    expect(ok.ok).toBe(true);
  });
});
