/**
 * CR-2/3/5/6: real care commands and tick against PostgreSQL.
 * Deliberately use the production clock hooks, not mocked repositories.
 */
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import { randomUUID } from 'crypto';

import { CARE_TICK_LOCK_KEY, runCareTick } from '../../lib/care/occurrence/careTick.js';
import { wallClockInTimeZone } from '../../lib/petHomeTimezone.js';
import {
  careApi, createDbPool, createOwner, invariantViolations, occurrenceRows, openHarness, removeOwner,
} from './helpers/careHarness.js';

let harness;
const owners = [];

beforeAll(async () => {
  harness = await openHarness();
  if (!harness.pool) {
    const probe = createDbPool();
    try {
      await probe.query(
        `SELECT 1 FROM information_schema.columns
         WHERE table_name = 'health_occurrences' AND column_name = 'origin'`,
      );
      throw new Error('Care DB integration tests require the migrated health_occurrences.origin column');
    } finally {
      await probe.end();
    }
  }
}, 30000);

afterAll(async () => {
  if (harness?.pool) {
    for (const owner of owners) await removeOwner(harness.pool, owner);
    await harness.pool.end();
  }
});

async function ownerIn(timeZone) {
  const owner = await createOwner(harness.pool, { timeZone });
  owners.push(owner);
  return careApi(harness.app, owner);
}

async function create(api, clock, body) {
  const response = await api.at(clock).create({
    name: 'Doses', care_family: 'medication', frequency: 'daily',
    next_due_date: clock.slice(0, 10), schedule_times: ['08:00', '18:00'], ...body,
  });
  expect(response.statusCode).toBe(201);
  return response.body;
}

async function ledger(entryId) {
  const { rows } = await harness.pool.query(
    `SELECT event_type, health_occurrence_id, actor_user_id, reason_code
     FROM care_schedule_events WHERE health_entry_id = $1 ORDER BY occurred_at, id`,
    [entryId],
  );
  return rows;
}

function open(rows) {
  return rows.filter((row) => row.status === 'pending');
}

function keys(rows) {
  return rows.map((row) => `${row.date} ${row.time}`);
}

function expectUniqueSlots(rows) {
  expect(new Set(keys(rows)).size).toBe(rows.length);
}

describe('catch-up, timezone boundaries and simultaneous commands', () => {
  it('CR-1 an overlapping tick skips the held advisory lock, then a later tick catches up once', async () => {
    const api = await ownerIn('UTC');
    const entry = await create(api, '2026-06-01T07:00', { schedule_times: ['08:00'] });
    const original = await occurrenceRows(harness.pool, entry.id);
    const holder = await harness.pool.connect();
    try {
      await holder.query('BEGIN');
      await holder.query('SELECT pg_advisory_xact_lock($1)', [CARE_TICK_LOCK_KEY]);
      // The holder's transaction remains open while the real production tick
      // attempts its own lock on a separate pool connection.
      const blocked = await runCareTick(harness.pool, {
        clock: { todayIso: '2026-06-05', nowTimeIso: '09:00' },
      });
      expect(blocked).toEqual({ skipped: true, processed: 0, created: 0, closed: 0 });
      expect(await occurrenceRows(harness.pool, entry.id)).toEqual(original);
    } finally {
      await holder.query('ROLLBACK');
      holder.release();
    }
    const catchup = await runCareTick(harness.pool, {
      clock: { todayIso: '2026-06-05', nowTimeIso: '09:00' },
    });
    expect(catchup.skipped).toBe(false);
    const first = await occurrenceRows(harness.pool, entry.id);
    expect(keys(first)).toEqual([
      '2026-06-01 08:00', '2026-06-02 08:00', '2026-06-03 08:00',
      '2026-06-04 08:00', '2026-06-05 08:00', '2026-06-06 08:00',
    ]);
    expect(first[0]).toMatchObject({ status: 'skipped', close_reason: 'not_recorded' });
    const firstLedger = await ledger(entry.id);
    expect(firstLedger.filter((e) => e.event_type === 'not_recorded_closed')).toHaveLength(1);
    await runCareTick(harness.pool, { clock: { todayIso: '2026-06-05', nowTimeIso: '09:00' } });
    expect(await occurrenceRows(harness.pool, entry.id)).toEqual(first);
    expect(await ledger(entry.id)).toEqual(firstLedger);
    expectUniqueSlots(first);
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('CR-2 a command catches up a two-hour-late tick before applying its skip', async () => {
    const api = await ownerIn('UTC');
    const entry = await create(api, '2026-06-05T21:00', { schedule_times: ['08:00'] });
    const first = entry.open_occurrences.find((row) => row.scheduled_date === '2026-06-05');
    expect(entry.open_occurrences.map((row) => row.scheduled_date)).toEqual(['2026-06-05', '2026-06-06']);

    // No tick since creation. The June 7 01:00 command is two hours after
    // the missed June 6 23:00 tick and must materialise June 7 and June 8.
    const skipped = await api.at('2026-06-07T01:00').skip(entry.id, first.id);
    expect(skipped.statusCode).toBe(200);
    expect(skipped.body.entry.as_of).toEqual({ date: '2026-06-07', time: '01:00', timezone: 'UTC' });
    expect(skipped.body.entry.open_occurrences.map((row) => row.scheduled_date))
      .toEqual(['2026-06-06', '2026-06-07', '2026-06-08']);
    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(keys(rows)).toEqual([
      '2026-06-05 08:00', '2026-06-06 08:00', '2026-06-07 08:00', '2026-06-08 08:00',
    ]);
    expect(rows[0]).toMatchObject({ id: first.id, status: 'skipped', close_reason: 'user' });
    expect(open(rows)).toHaveLength(3);
    expectUniqueSlots(rows);
    expect((await ledger(entry.id)).filter((e) => e.event_type === 'skipped'))
      .toEqual([expect.objectContaining({ health_occurrence_id: first.id })]);
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('CR-3 one instant straddles the Tokyo/UTC calendar boundary for two pets', async () => {
    const tokyo = await ownerIn('Asia/Tokyo');
    const utc = await ownerIn('UTC');
    const tokyoEntry = await create(tokyo, '2026-06-01T10:00', { schedule_times: ['08:00'] });
    const utcEntry = await create(utc, '2026-06-01T10:00', { schedule_times: ['08:00'] });

    // UTC June 1 15:10 is Tokyo June 2 00:10; use a real instant, not
    // the test-only local-clock override.
    const stats = await runCareTick(harness.pool, { now: new Date('2026-06-01T15:10:00Z') });
    expect(stats.skipped).toBe(false);
    expect(stats.created).toBeGreaterThanOrEqual(1);
    const tokyoRows = await occurrenceRows(harness.pool, tokyoEntry.id);
    const utcRows = await occurrenceRows(harness.pool, utcEntry.id);
    expect(keys(tokyoRows)).toEqual(['2026-06-01 08:00', '2026-06-02 08:00', '2026-06-03 08:00']);
    expect(keys(utcRows)).toEqual(['2026-06-01 08:00', '2026-06-02 08:00']);
    expectUniqueSlots(tokyoRows);
    expectUniqueSlots(utcRows);
    const tokyoRead = await tokyo.at('2026-06-02T00:10').get(tokyoEntry.id);
    const utcRead = await utc.at('2026-06-01T15:10').get(utcEntry.id);
    expect(tokyoRead.statusCode).toBe(200);
    expect(utcRead.statusCode).toBe(200);
    expect(tokyoRead.body.as_of).toEqual({ date: '2026-06-02', time: '00:10', timezone: 'Asia/Tokyo' });
    expect(utcRead.body.as_of).toEqual({ date: '2026-06-01', time: '15:10', timezone: 'UTC' });
    expect(tokyoRead.body.open_occurrences.map((r) => r.status)).toEqual(['overdue', 'due', 'coming_up']);
    expect(utcRead.body.open_occurrences.map((r) => r.status)).toEqual(['overdue', 'coming_up']);
    expect(await invariantViolations(harness.pool, tokyoEntry.id)).toEqual([]);
    expect(await invariantViolations(harness.pool, utcEntry.id)).toEqual([]);
  });

  it('CR-5 concurrent completion of different stack slots commits both, with two ledger events', async () => {
    const primary = await createOwner(harness.pool, { timeZone: 'Europe/Paris' });
    const secondCarer = await createOwner(harness.pool, { timeZone: 'Europe/Paris' });
    owners.push(primary, secondCarer);
    await harness.pool.query(
      `INSERT INTO pet_access (id, pet_id, user_id, role) VALUES ($1, $2, $3, 'co_parent')`,
      [randomUUID(), primary.petId, secondCarer.userId],
    );
    const api = careApi(harness.app, primary);
    const otherApi = careApi(harness.app, { ...secondCarer, petId: primary.petId });
    const entry = await create(api, '2026-06-01T07:00');
    const [morning, evening] = entry.open_occurrences.filter((r) => r.scheduled_date === '2026-06-01');
    const responses = await Promise.all([
      api.at('2026-06-02T19:00').complete(entry.id, morning.id, { completed_on: '2026-06-01' }),
      otherApi.at('2026-06-02T19:00').complete(entry.id, evening.id, { completed_on: '2026-06-01' }),
    ]);
    expect(responses.map((r) => r.statusCode)).toEqual([200, 200]);
    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.filter((r) => [morning.id, evening.id].includes(r.id)))
      .toEqual([
        expect.objectContaining({ id: morning.id, status: 'completed', completed_on: '2026-06-01' }),
        expect.objectContaining({ id: evening.id, status: 'completed', completed_on: '2026-06-01' }),
      ]);
    expect(keys(open(rows))).toEqual([
      '2026-06-02 08:00', '2026-06-02 18:00', '2026-06-03 08:00', '2026-06-03 18:00',
    ]);
    expectUniqueSlots(rows);
    const completed = (await ledger(entry.id)).filter((e) => e.event_type === 'completed');
    expect(completed).toHaveLength(2);
    expect(new Set(completed.map((e) => e.health_occurrence_id)))
      .toEqual(new Set([morning.id, evening.id]));
    expect(new Set(completed.map((e) => e.actor_user_id)))
      .toEqual(new Set([primary.userId, secondCarer.userId]));
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('CR-4 two authorized carers race for one dose: only one completion and one ledger event', async () => {
    const primary = await createOwner(harness.pool);
    const secondCarer = await createOwner(harness.pool);
    owners.push(primary, secondCarer);
    await harness.pool.query(
      `INSERT INTO pet_access (id, pet_id, user_id, role) VALUES ($1, $2, $3, 'co_parent')`,
      [randomUUID(), primary.petId, secondCarer.userId],
    );
    const api = careApi(harness.app, primary);
    const otherApi = careApi(harness.app, { ...secondCarer, petId: primary.petId });
    const entry = await create(api, '2026-06-05T07:00', { schedule_times: ['08:00'] });
    const dose = entry.open_occurrences[0];
    const responses = await Promise.all([
      api.at('2026-06-05T09:00').complete(entry.id, dose.id),
      otherApi.at('2026-06-05T09:00').complete(entry.id, dose.id),
    ]);
    expect(responses.map((r) => r.statusCode).sort()).toEqual([200, 409]);
    expect(responses.find((r) => r.statusCode === 409).body.code).toBe('occurrence_not_open');
    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.filter((r) => r.id === dose.id)).toEqual([
      expect.objectContaining({ status: 'completed', completed_on: '2026-06-05' }),
    ]);
    expect(keys(open(rows))).toEqual(['2026-06-06 08:00']);
    expectUniqueSlots(rows);
    const completed = (await ledger(entry.id)).filter((e) => e.event_type === 'completed');
    expect(completed).toHaveLength(1);
    expect(completed[0].health_occurrence_id).toBe(dose.id);
    expect([primary.userId, secondCarer.userId]).toContain(completed[0].actor_user_id);
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('CR-6 Paris spring-forward 02:30 persists; at 03:00 it is due, tick repeats without duplicates', async () => {
    const api = await ownerIn('Europe/Paris');
    const entry = await create(api, '2027-03-27T12:00', {
      next_due_date: '2027-03-28', schedule_times: ['02:30'],
    });
    const before = await api.at('2027-03-28T01:59').get(entry.id);
    expect(before.statusCode).toBe(200);
    expect(before.body.open_occurrences[0]).toMatchObject({
      scheduled_date: '2027-03-28', scheduled_time: '02:30', status: 'due',
    });
    const instant = new Date('2027-03-28T01:00:00Z'); // Paris 03:00 after the jump
    const firstTick = await runCareTick(harness.pool, { now: instant });
    expect(firstTick.skipped).toBe(false);
    const atThree = await api.at('2027-03-28T03:00').get(entry.id);
    expect(atThree.statusCode).toBe(200);
    expect(atThree.body.as_of).toEqual({ date: '2027-03-28', time: '03:00', timezone: 'Europe/Paris' });
    expect(atThree.body.open_occurrences[0]).toMatchObject({
      scheduled_date: '2027-03-28', scheduled_time: '02:30', status: 'due',
    });
    const snapshot = await occurrenceRows(harness.pool, entry.id);
    expect(keys(snapshot)).toEqual(['2027-03-28 02:30', '2027-03-29 02:30']);
    await runCareTick(harness.pool, { now: instant });
    expect(await occurrenceRows(harness.pool, entry.id)).toEqual(snapshot);
    expect((await ledger(entry.id)).filter((e) => e.event_type === 'not_recorded_closed')).toHaveLength(0);
    expect((await api.at('2027-03-28T03:01').get(entry.id)).body.open_occurrences[0].status).toBe('overdue');
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('CR-7 two distinct UTC instants in Paris repeated 02:30 do not close twice or duplicate slots', async () => {
    const api = await ownerIn('Europe/Paris');
    const entry = await create(api, '2026-10-20T07:00', { schedule_times: ['02:30'] });
    const firstInstant = new Date('2026-10-25T00:30:00Z');
    const secondInstant = new Date('2026-10-25T01:30:00Z');
    expect(wallClockInTimeZone('Europe/Paris', firstInstant))
      .toEqual({ todayIso: '2026-10-25', nowTimeIso: '02:30' });
    expect(wallClockInTimeZone('Europe/Paris', secondInstant))
      .toEqual({ todayIso: '2026-10-25', nowTimeIso: '02:30' });
    const firstTick = await runCareTick(harness.pool, { now: firstInstant });
    expect(firstTick.skipped).toBe(false);
    const first = await occurrenceRows(harness.pool, entry.id);
    expect(keys(first)).toEqual([
      '2026-10-20 02:30', '2026-10-21 02:30', '2026-10-22 02:30',
      '2026-10-23 02:30', '2026-10-24 02:30', '2026-10-25 02:30', '2026-10-26 02:30',
    ]);
    expect(first.filter((row) => row.close_reason === 'not_recorded').map((row) => row.date))
      .toEqual(['2026-10-20', '2026-10-21']);
    const firstLedger = await ledger(entry.id);
    expect(firstLedger.filter((e) => e.event_type === 'not_recorded_closed')).toHaveLength(1);
    const repeatedTick = await runCareTick(harness.pool, { now: secondInstant });
    expect(repeatedTick.skipped).toBe(false);
    expect(repeatedTick.created).toBe(0);
    expect(repeatedTick.closed).toBe(0);
    expect(await occurrenceRows(harness.pool, entry.id)).toEqual(first);
    expect(await ledger(entry.id)).toEqual(firstLedger);
    expectUniqueSlots(first);
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });
});