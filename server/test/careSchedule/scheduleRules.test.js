import { describe, expect, it } from '@jest/globals';

import {
  addMonthsClamped,
  seriesDateAfter,
  seriesDatesBetween,
} from '../../lib/care/schedule/seriesDates.js';
import {
  expectedFixedSlots,
  nextSeriesSlotAfter,
} from '../../lib/care/schedule/fixedSlots.js';
import { occurrenceStatus } from '../../lib/care/schedule/occurrenceStatus.js';
import {
  estimatedNextWhileOverdue,
  nextComputedDate,
} from '../../lib/care/schedule/nextComputed.js';
import {
  evaluateNextChoice,
  pickWaitingOccurrence,
} from '../../lib/care/schedule/lateCompletion.js';
import { advanceByFrequency } from '../../lib/recurrenceHelper.js';

const monthly = { frequency: 'monthly', frequency_interval: 1 };
const yearly = { frequency: 'yearly', frequency_interval: 1 };

function fixed(overrides = {}) {
  return {
    frequency: 'daily',
    frequency_interval: 1,
    recurrence_anchor: 'from_due_date',
    status: 'active',
    schedule_anchor_date: '2026-06-01',
    schedule_times: null,
    repeat_end_date: null,
    ...overrides,
  };
}

describe('month-end clamp (D-CSM-024)', () => {
  it('ME-1 monthly anchored on 31 Jan counts from the anchor', () => {
    expect(seriesDatesBetween('2027-01-31', monthly, '2027-01-01', '2027-05-31')).toEqual([
      '2027-01-31', '2027-02-28', '2027-03-31', '2027-04-30', '2027-05-31',
    ]);
    expect(seriesDatesBetween('2028-01-31', monthly, '2028-02-01', '2028-02-29')).toEqual(['2028-02-29']);
  });

  it('ME-2 every six months from 31 Aug', () => {
    const entry = { frequency: 'monthly', frequency_interval: 6 };
    expect(seriesDatesBetween('2026-08-31', entry, '2026-09-01', '2027-12-31')).toEqual([
      '2027-02-28', '2027-08-31',
    ]);
  });

  it('ME-3 yearly from 29 Feb 2028', () => {
    expect(seriesDatesBetween('2028-02-29', yearly, '2029-01-01', '2032-12-31')).toEqual([
      '2029-02-28', '2030-02-28', '2031-02-28', '2032-02-29',
    ]);
  });

  it('ME-4 after-it\'s-done monthly done 31 Jan', () => {
    expect(advanceByFrequency('2027-01-31', monthly)).toBe('2027-02-28');
    expect(addMonthsClamped('2027-02-28', 1)).toBe('2027-03-28');
  });

  it('ME-5 this-and-following moved to 31 Oct', () => {
    expect(seriesDatesBetween('2026-10-31', monthly, '2026-11-01', '2026-12-31')).toEqual([
      '2026-11-30', '2026-12-31',
    ]);
  });

  it('finds the next series date after a day', () => {
    expect(seriesDateAfter('2026-01-05', { frequency: 'weekly', frequency_interval: 1 }, '2026-01-12'))
      .toBe('2026-01-19');
  });
});

describe('fixed-schedule slots (D-CSM-023)', () => {
  it('FX-1 twice daily keeps today and tomorrow', () => {
    const entry = fixed({ schedule_times: ['18:00', '08:00'], schedule_anchor_date: '2026-06-05' });
    expect(expectedFixedSlots({ entry, todayIso: '2026-06-05' })).toEqual([
      { date: '2026-06-05', time: '08:00' },
      { date: '2026-06-05', time: '18:00' },
      { date: '2026-06-06', time: '08:00' },
      { date: '2026-06-06', time: '18:00' },
    ]);
  });

  it('keeps today − 3 days through today plus the next date', () => {
    const entry = fixed({ schedule_anchor_date: '2026-06-01' });
    expect(expectedFixedSlots({ entry, todayIso: '2026-06-10' }).map((s) => s.date)).toEqual([
      '2026-06-07', '2026-06-08', '2026-06-09', '2026-06-10', '2026-06-11',
    ]);
  });

  it('a monthly dose from a week ago stays stored while it is only overdue', () => {
    const entry = fixed({ frequency: 'monthly', schedule_anchor_date: '2026-06-03' });
    expect(expectedFixedSlots({ entry, todayIso: '2026-06-10' }).map((s) => s.date)).toEqual([
      '2026-06-03', '2026-07-03',
    ]);
  });

  it('a future anchor only stores the first date', () => {
    const entry = fixed({ frequency: 'monthly', schedule_anchor_date: '2026-07-31' });
    expect(expectedFixedSlots({ entry, todayIso: '2026-06-10' })).toEqual([
      { date: '2026-07-31', time: null },
    ]);
  });

  it('never stores slots before a resume date or after the end date', () => {
    const entry = fixed({ series_resumed_on: '2026-06-09', repeat_end_date: '2026-06-10' });
    expect(expectedFixedSlots({ entry, todayIso: '2026-06-10' }).map((s) => s.date)).toEqual([
      '2026-06-09', '2026-06-10',
    ]);
  });

  it('paused items get no new slots', () => {
    expect(expectedFixedSlots({ entry: fixed({ status: 'paused' }), todayIso: '2026-06-10' })).toEqual([]);
  });

  it('finds the next slot of the series', () => {
    const entry = fixed({ schedule_times: ['08:00', '18:00'] });
    expect(nextSeriesSlotAfter({ entry, date: '2026-06-05', time: '08:00' }))
      .toEqual({ date: '2026-06-05', time: '18:00' });
    expect(nextSeriesSlotAfter({ entry, date: '2026-06-05', time: '18:00' }))
      .toEqual({ date: '2026-06-06', time: '08:00' });
  });
});

describe('occurrence status (D-CIE-024)', () => {
  const twiceDaily = fixed({ schedule_times: ['08:00', '18:00'] });
  const at = (todayIso, nowTimeIso) => ({ todayIso, nowTimeIso });
  const occ = (date, time) => ({ scheduled_date: date, scheduled_time: time });

  it('coming up before its day, due on its day until its time', () => {
    expect(occurrenceStatus({ occurrence: occ('2026-06-06', '08:00'), entry: twiceDaily, asOf: at('2026-06-05', '07:00') })).toBe('coming_up');
    expect(occurrenceStatus({ occurrence: occ('2026-06-05', '08:00'), entry: twiceDaily, asOf: at('2026-06-05', '07:00') })).toBe('due');
  });

  it('FX-2 overdue after its time until the next slot', () => {
    expect(occurrenceStatus({ occurrence: occ('2026-06-05', '08:00'), entry: twiceDaily, asOf: at('2026-06-05', '12:00') })).toBe('overdue');
  });

  it('FX-3 not recorded once the next slot is due', () => {
    expect(occurrenceStatus({ occurrence: occ('2026-06-05', '08:00'), entry: twiceDaily, asOf: at('2026-06-05', '18:01') })).toBe('not_recorded');
  });

  it('after-it\'s-done care stays overdue', () => {
    const entry = { frequency: 'monthly', recurrence_anchor: 'from_completion' };
    expect(occurrenceStatus({ occurrence: occ('2026-05-05', null), entry, asOf: at('2026-06-20', '10:00') })).toBe('overdue');
  });

  it('CR-6 spring-forward 02:30 is due at the first real minute 03:00, not 03:30', () => {
    const entry = fixed({ schedule_times: ['02:30'] });
    const status = (time, zone = 'Europe/Paris') => occurrenceStatus({
      occurrence: occ('2027-03-28', '02:30'), entry,
      asOf: { ...at('2027-03-28', time), timeZone: zone },
    });
    expect(status('01:59')).toBe('due');
    expect(status('03:00')).toBe('due');
    expect(status('03:01')).toBe('overdue');
    expect(status('03:30')).toBe('overdue');
    expect(status('02:31', 'UTC')).toBe('overdue');
  });

  it('normal and repeated autumn times keep their actual wall time', () => {
    const entry = fixed({ schedule_times: ['02:30'] });
    for (const date of ['2027-03-27', '2027-10-31']) {
      const status = (time) => occurrenceStatus({
        occurrence: occ(date, '02:30'), entry,
        asOf: { ...at(date, time), timeZone: 'Europe/Paris' },
      });
      expect(status('02:29')).toBe('due');
      expect(status('02:30')).toBe('due');
      expect(status('02:31')).toBe('overdue');
    }
  });

  it('Lord Howe half-hour spring gap moves 02:15 to 02:30, not 02:45', () => {
    const entry = fixed({ schedule_times: ['02:15'] });
    const status = (date, time) => occurrenceStatus({
      occurrence: occ(date, '02:15'), entry,
      asOf: { ...at(date, time), timeZone: 'Australia/Lord_Howe' },
    });
    expect(status('2027-10-03', '01:59')).toBe('due');
    expect(status('2027-10-03', '02:30')).toBe('due');
    expect(status('2027-10-03', '02:31')).toBe('overdue');
    expect(status('2027-10-02', '02:15')).toBe('due');
    expect(status('2027-10-02', '02:16')).toBe('overdue');
    // The autumn 01:30 hour is repeated, not a missing wall time.
    const autumn = (time) => occurrenceStatus({
      occurrence: occ('2027-04-04', '01:45'), entry,
      asOf: { ...at('2027-04-04', time), timeZone: 'Australia/Lord_Howe' },
    });
    expect(autumn('01:45')).toBe('due');
    expect(autumn('01:46')).toBe('overdue');
  });
});

describe('after it\'s done (D-CSM-022)', () => {
  it('AID-1 / AID-3 counts from the done date', () => {
    expect(nextComputedDate({ entry: monthly, lastClosed: { status: 'completed', scheduled_date: '2026-06-05', completed_on: '2026-06-05' }, todayIso: '2026-06-05' })).toBe('2026-07-05');
    expect(nextComputedDate({ entry: monthly, lastClosed: { status: 'completed', scheduled_date: '2026-06-05', completed_on: '2026-06-06' }, todayIso: '2026-06-07' })).toBe('2026-07-06');
  });

  it('AID-4 a skip counts from today when later than the due date', () => {
    expect(nextComputedDate({ entry: monthly, lastClosed: { status: 'skipped', scheduled_date: '2026-06-05' }, todayIso: '2026-06-07' })).toBe('2026-07-07');
  });

  it('AID-6 yearly done late', () => {
    expect(nextComputedDate({ entry: yearly, lastClosed: { status: 'completed', scheduled_date: '2026-03-01', completed_on: '2026-04-15' }, todayIso: '2026-04-15' })).toBe('2027-04-15');
  });

  it('AID-2 estimated next moves with today', () => {
    expect(estimatedNextWhileOverdue({ entry: monthly, todayIso: '2026-06-07' })).toBe('2026-07-07');
  });
});

describe('next-date choice (D-CSM-026)', () => {
  const weekly = { frequency: 'weekly', frequency_interval: 1 };
  const mon = { scheduled_date: '2026-06-01', scheduled_time: null };
  const nextMon = { scheduled_date: '2026-06-08', scheduled_time: null };

  it('FX-7 done Wednesday does not ask', () => {
    expect(evaluateNextChoice({ closed: mon, waiting: nextMon, completedOn: '2026-06-03', entry: weekly }).required).toBe(false);
  });

  it('FX-8 done Saturday asks with a five-day shift', () => {
    expect(evaluateNextChoice({ closed: mon, waiting: nextMon, completedOn: '2026-06-06' })).toEqual({
      required: true,
      shift: { days: 5 },
      options: ['keep', 'skip_next', 'shift_following'],
    });
  });

  it('PL-2 booster waiting after a late first dose', () => {
    const result = evaluateNextChoice({
      closed: { scheduled_date: '2026-06-01', scheduled_time: null },
      waiting: { scheduled_date: '2026-07-01', scheduled_time: null },
      completedOn: '2026-06-20',
    });
    expect(result).toMatchObject({ required: true, shift: { days: 19 } });
  });

  it('LC-3 twice-daily dose recorded at 15:00 asks without a move option', () => {
    const result = evaluateNextChoice({
      closed: { scheduled_date: '2026-06-05', scheduled_time: '08:00' },
      waiting: { scheduled_date: '2026-06-05', scheduled_time: '18:00' },
      completedOn: '2026-06-05',
      completedTime: '15:00',
      multiTime: true,
    });
    expect(result).toEqual({ required: true, shift: { minutes: 420 }, options: ['keep', 'skip_next'] });
  });

  it('on time never asks', () => {
    expect(evaluateNextChoice({ closed: mon, waiting: nextMon, completedOn: '2026-06-01' }).required).toBe(false);
  });

  it('picks the earliest future planned or scheduled date', () => {
    const closed = { id: 'a', scheduled_date: '2026-06-01', scheduled_time: null };
    const waiting = pickWaitingOccurrence({
      closed,
      openOccurrences: [
        { id: 'b', origin: 'computed', scheduled_date: '2026-06-10', scheduled_time: null },
        { id: 'c', origin: 'planned', scheduled_date: '2026-07-01', scheduled_time: null },
        { id: 'd', origin: 'planned', scheduled_date: '2026-06-15', scheduled_time: null },
      ],
      asOf: { todayIso: '2026-06-06', nowTimeIso: '10:00' },
    });
    expect(waiting.id).toBe('d');
  });
});
