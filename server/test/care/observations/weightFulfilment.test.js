import { describe, expect, it } from '@jest/globals';

import { isFulfilmentEligible } from '../../../lib/care/observations/weightFulfilment.js';

const monthlyEntry = {
  care_family: 'weight_monitoring',
  status: 'active',
  frequency: 'monthly',
  frequency_interval: 1,
  start_date: null,
};

const baseOccurrence = {
  status: 'pending',
  scheduled_date: '2026-10-10',
};

const todayIso = '2026-10-12';

function eligible(dateIso, overrides = {}) {
  const entry = { ...monthlyEntry, ...(overrides.entry || {}) };
  const occurrence = { ...baseOccurrence, ...(overrides.occurrence || {}) };
  return isFulfilmentEligible({
    entry,
    occurrence,
    dateIso,
    todayIso: overrides.todayIso ?? todayIso,
    latestCompletedOn: overrides.latestCompletedOn ?? null,
  });
}

describe('weight fulfilment rule (F-1…F-10)', () => {
  it('F-1 date 2026-10-12 is eligible', () => {
    expect(eligible('2026-10-12')).toBe(true);
  });

  it('F-2 date 2026-09-25 window start is eligible', () => {
    expect(eligible('2026-09-25')).toBe(true);
  });

  it('F-3 date 2026-09-24 before window is not eligible', () => {
    expect(eligible('2026-09-24')).toBe(false);
  });

  it('F-4 date 2026-10-13 future is not eligible', () => {
    expect(eligible('2026-10-13')).toBe(false);
  });

  it('F-5 date 2026-10-05 with latest completed_on 2026-10-06 is not eligible', () => {
    expect(eligible('2026-10-05', { latestCompletedOn: '2026-10-06' })).toBe(false);
  });

  it('F-6 routine paused is not eligible', () => {
    expect(eligible('2026-10-05', { entry: { status: 'paused' } })).toBe(false);
  });

  it('F-7 routine closed is not eligible', () => {
    expect(eligible('2026-10-05', { entry: { status: 'closed' } })).toBe(false);
  });

  it('F-8 family dental is not eligible', () => {
    expect(eligible('2026-10-05', { entry: { care_family: 'dental' } })).toBe(false);
  });

  it('F-9 one-off on scheduled day is eligible; day before is not', () => {
    const onceEntry = {
      care_family: 'weight_monitoring',
      status: 'active',
      frequency: 'once',
      start_date: null,
    };
    const occ = { status: 'pending', scheduled_date: '2026-10-10' };
    expect(isFulfilmentEligible({
      entry: onceEntry,
      occurrence: occ,
      dateIso: '2026-10-10',
      todayIso,
      latestCompletedOn: null,
    })).toBe(true);
    expect(isFulfilmentEligible({
      entry: onceEntry,
      occurrence: occ,
      dateIso: '2026-10-09',
      todayIso,
      latestCompletedOn: null,
    })).toBe(false);
  });

  it('F-10 start_date 2026-10-06 blocks 2026-10-05', () => {
    expect(eligible('2026-10-05', { entry: { start_date: '2026-10-06' } })).toBe(false);
  });
});
