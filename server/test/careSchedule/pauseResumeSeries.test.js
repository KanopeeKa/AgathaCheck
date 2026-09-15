import { describe, expect, it } from '@jest/globals';
import { v4 as uuidv4 } from 'uuid';

import {
  pauseSeries,
  resumeSeries,
} from '../../lib/care/schedule/pauseResumeSeries.js';
import {
  SCHEDULE_EVENT_PAUSED,
  SCHEDULE_EVENT_RESUMED,
} from '../../lib/care/schedule/scheduleEventLedger.js';
import { SCHEDULE_POLICY_VERSION } from '../../lib/care/schedule/schedulePolicy.js';

function makeEntry(overrides = {}) {
  return {
    id: 'he-1',
    frequency: 'daily',
    frequency_interval: 1,
    start_date: new Date('2026-09-01'),
    next_due_date: new Date('2026-09-05'),
    recurrence_anchor: 'from_completion',
    status: 'active',
    paused_since: null,
    schedule_times: null,
    repeat_end_date: null,
    ...overrides,
  };
}

function makeOccurrence(overrides = {}) {
  return {
    id: uuidv4(),
    health_entry_id: 'he-1',
    scheduled_date: new Date('2026-09-01'),
    scheduled_time: null,
    status: 'pending',
    completed_on: null,
    marked_at: null,
    marked_by_user_id: null,
    notes: '',
    ...overrides,
  };
}

function createHarness(initialEntry, initialOccurrences = []) {
  let entry = { ...initialEntry };
  const occurrences = [...initialOccurrences];
  const ledgerEvents = [];
  const insertedDates = [];

  const pool = {
    query: async (sql, params) => {
      if (
        sql.includes("UPDATE health_entries SET status = 'paused'")
        && sql.includes('paused_since = $1')
      ) {
        if (entry.status !== 'active') return { rows: [] };
        entry = {
          ...entry,
          status: 'paused',
          paused_since: new Date(params[0]),
        };
        return { rows: [entry] };
      }

      if (
        sql.includes("UPDATE health_entries SET status = 'active'")
        && sql.includes('paused_since = NULL')
      ) {
        if (entry.status !== 'paused') return { rows: [] };
        entry = {
          ...entry,
          status: 'active',
          paused_since: null,
        };
        return { rows: [entry] };
      }

      if (sql.includes('INSERT INTO care_schedule_events')) {
        ledgerEvents.push({
          id: params[0],
          health_entry_id: params[1],
          health_occurrence_id: params[2],
          event_type: params[3],
          from_date: params[4],
          to_date: params[5],
          from_anchor: params[6],
          to_anchor: params[7],
          reason_code: params[8],
          reason_note: params[9],
          actor_user_id: params[10],
          occurred_at: params[11],
          effective_from: params[12],
          idempotency_key: params[13],
          policy_version: params[14],
        });
        return { rows: [] };
      }

      if (sql.includes('INSERT INTO health_occurrences')) {
        insertedDates.push(params[2]);
        occurrences.push(makeOccurrence({
          id: params[0],
          health_entry_id: params[1],
          scheduled_date: new Date(params[2]),
          scheduled_time: params[3],
        }));
        return { rows: [] };
      }

      return { rows: [] };
    },
  };

  return {
    pool,
    get entry() {
      return entry;
    },
    occurrences,
    ledgerEvents,
    insertedDates,
  };
}

describe('pauseSeries', () => {
  it('sets status paused, paused_since cache, and writes ledger event', async () => {
    const initial = makeEntry();
    const harness = createHarness(initial);

    const result = await pauseSeries(harness.pool, {
      entry: initial,
      userId: 'user-1',
      pausedFrom: '2026-09-05',
      reasonCode: 'travel',
      reasonNote: 'Away for a week',
    });

    expect(result).not.toBeNull();
    expect(harness.entry.status).toBe('paused');
    expect(harness.entry.paused_since).toEqual(new Date('2026-09-05'));
    expect(result.pausedSince).toBe('2026-09-05');
    expect(harness.ledgerEvents).toHaveLength(1);
    expect(harness.ledgerEvents[0]).toMatchObject({
      health_entry_id: initial.id,
      event_type: SCHEDULE_EVENT_PAUSED,
      from_date: '2026-09-05',
      reason_code: 'travel',
      reason_note: 'Away for a week',
      actor_user_id: 'user-1',
      idempotency_key: `paused:${initial.id}:2026-09-05`,
      policy_version: SCHEDULE_POLICY_VERSION,
    });
  });

  it('returns null when entry is not active', async () => {
    const initial = makeEntry({ status: 'paused', paused_since: new Date('2026-09-01') });
    const harness = createHarness(initial);

    const result = await pauseSeries(harness.pool, {
      entry: initial,
      userId: 'user-1',
    });

    expect(result).toBeNull();
    expect(harness.ledgerEvents).toHaveLength(0);
  });
});

describe('resumeSeries', () => {
  it('clears pause state and writes resumed ledger event', async () => {
    const initial = makeEntry({
      status: 'paused',
      paused_since: new Date('2026-09-05'),
    });
    const harness = createHarness(initial);

    const result = await resumeSeries(harness.pool, {
      entry: initial,
      userId: 'user-1',
      reasonNote: 'Back home',
    });

    expect(result).not.toBeNull();
    expect(harness.entry.status).toBe('active');
    expect(harness.entry.paused_since).toBeNull();
    expect(harness.ledgerEvents).toHaveLength(1);
    expect(harness.ledgerEvents[0]).toMatchObject({
      health_entry_id: initial.id,
      event_type: SCHEDULE_EVENT_RESUMED,
      from_date: '2026-09-05',
      reason_note: 'Back home',
      actor_user_id: 'user-1',
      idempotency_key: `resumed:${initial.id}:2026-09-05`,
      policy_version: SCHEDULE_POLICY_VERSION,
    });
  });

  it('returns null when entry is not paused', async () => {
    const initial = makeEntry();
    const harness = createHarness(initial);

    const result = await resumeSeries(harness.pool, {
      entry: initial,
      userId: 'user-1',
    });

    expect(result).toBeNull();
    expect(harness.ledgerEvents).toHaveLength(0);
  });

  it('does not create catch-up occurrences when resuming', async () => {
    const pending = makeOccurrence({ scheduled_date: new Date('2026-09-02') });
    const initial = makeEntry({
      status: 'paused',
      paused_since: new Date('2026-09-05'),
      next_due_date: new Date('2026-09-02'),
    });
    const harness = createHarness(initial, [pending]);

    await resumeSeries(harness.pool, {
      entry: initial,
      userId: 'user-1',
    });

    expect(harness.insertedDates).toEqual([]);
    expect(harness.occurrences).toHaveLength(1);
    expect(harness.occurrences[0].status).toBe('pending');
  });
});
