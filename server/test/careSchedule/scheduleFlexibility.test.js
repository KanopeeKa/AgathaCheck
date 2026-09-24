import { describe, expect, it } from '@jest/globals';

import { resolveScheduleFlexibility } from '../../lib/care/schedule/scheduleFlexibility.js';

describe('resolveScheduleFlexibility', () => {
  const today = '2026-09-24';

  it('returns fixed for vet_instruction and treatment_schedule', () => {
    expect(
      resolveScheduleFlexibility(
        { care_source: 'vet_instruction', frequency: 'monthly', frequency_interval: 1 },
        today,
      ),
    ).toEqual({ flexibility: 'fixed', max_shift_days: 0 });
    expect(
      resolveScheduleFlexibility(
        { care_source: 'treatment_schedule', frequency: 'weekly', frequency_interval: 1 },
        today,
      ),
    ).toEqual({ flexibility: 'fixed', max_shift_days: 0 });
  });

  it('returns earlier_only for vaccination and parasite_prevention', () => {
    const result = resolveScheduleFlexibility(
      {
        care_family: 'vaccination',
        frequency: 'yearly',
        frequency_interval: 1,
      },
      today,
    );
    expect(result.flexibility).toBe('earlier_only');
    expect(result.max_shift_days).toBeGreaterThanOrEqual(0);
    expect(result.max_shift_days).toBeLessThanOrEqual(7);
  });

  it('returns carer_task for daily and multi-time schedules', () => {
    expect(
      resolveScheduleFlexibility(
        { frequency: 'daily', frequency_interval: 1 },
        today,
      ),
    ).toEqual({ flexibility: 'carer_task', max_shift_days: 0 });
    expect(
      resolveScheduleFlexibility(
        {
          frequency: 'daily',
          frequency_interval: 1,
          schedule_times: ['08:00', '20:00'],
        },
        today,
      ),
    ).toEqual({ flexibility: 'carer_task', max_shift_days: 0 });
  });

  it('returns flexible with capped max_shift_days for monthly meds', () => {
    const result = resolveScheduleFlexibility(
      {
        care_family: 'medication',
        care_source: 'guardian_defined',
        frequency: 'monthly',
        frequency_interval: 1,
      },
      today,
    );
    expect(result.flexibility).toBe('flexible');
    expect(result.max_shift_days).toBe(7);
  });
});
