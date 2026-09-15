import { describe, expect, it } from '@jest/globals';
import { v4 as uuidv4 } from 'uuid';

import { undoLastAction } from '../../lib/care/schedule/undoLastAction.js';
import { SCHEDULE_EVENT_SKIPPED } from '../../lib/care/schedule/scheduleEventLedger.js';

function makeEntry(overrides = {}) {
  return {
    id: 'he-1',
    frequency: 'daily',
    frequency_interval: 1,
    start_date: new Date('2026-09-01'),
    next_due_date: new Date('2026-09-01'),
    recurrence_anchor: 'from_completion',
    status: 'active',
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
    completion_timing: null,
    marked_at: null,
    marked_by_user_id: null,
    notes: '',
    ...overrides,
  };
}

function createHarness(entry, initialOccurrences = [], ledgerEvents = []) {
  const occurrences = [...initialOccurrences];
  const events = [...ledgerEvents];
  let nextDueDate = '2026-09-01';

  const pool = {
    query: async (sql, params) => {
      if (
        sql.includes('SELECT * FROM health_occurrences')
        && sql.includes("status IN ('completed', 'skipped')")
        && sql.includes('ORDER BY marked_at DESC')
      ) {
        const closed = occurrences
          .filter((o) => o.health_entry_id === params[0] && ['completed', 'skipped'].includes(o.status))
          .sort((a, b) => new Date(b.marked_at) - new Date(a.marked_at));
        return { rows: closed.length > 0 ? [closed[0]] : [] };
      }

      if (
        sql.includes('SELECT * FROM care_schedule_events')
        && sql.includes('ORDER BY occurred_at DESC')
      ) {
        const sorted = events
          .filter((e) => e.health_entry_id === params[0])
          .sort((a, b) => new Date(b.occurred_at) - new Date(a.occurred_at));
        return { rows: sorted.length > 0 ? [sorted[0]] : [] };
      }

      if (
        sql.includes('UPDATE health_occurrences SET status = \'pending\'')
        && sql.includes('completion_timing = NULL')
      ) {
        const idx = occurrences.findIndex(
          (o) => o.id === params[0] && o.health_entry_id === params[1]
            && ['completed', 'skipped'].includes(o.status),
        );
        if (idx < 0) return { rows: [] };
        occurrences[idx] = {
          ...occurrences[idx],
          status: 'pending',
          completed_on: null,
          completion_timing: null,
          marked_at: null,
          marked_by_user_id: null,
          notes: '',
        };
        return { rows: [occurrences[idx]] };
      }

      if (
        sql.includes('SELECT scheduled_date, scheduled_time FROM health_occurrences')
        && sql.includes("status = 'pending'")
      ) {
        const pending = occurrences
          .filter((o) => o.health_entry_id === params[0] && o.status === 'pending')
          .sort((a, b) => a.scheduled_date - b.scheduled_date);
        return {
          rows: pending.length > 0
            ? [{
              scheduled_date: pending[0].scheduled_date,
              scheduled_time: pending[0].scheduled_time,
            }]
            : [],
        };
      }

      if (sql.includes('UPDATE health_entries SET next_due_date')) {
        nextDueDate = params[0];
        return { rows: [] };
      }

      if (sql.includes('SELECT * FROM health_entries WHERE id = $1')) {
        return {
          rows: [{
            ...entry,
            next_due_date: nextDueDate ? new Date(nextDueDate) : null,
          }],
        };
      }

      return { rows: [] };
    },
  };

  return {
    pool,
    occurrences,
    events,
    get nextDueDate() {
      return nextDueDate;
    },
  };
}

describe('undoLastAction', () => {
  it('returns null when no schedule actions exist', async () => {
    const entry = makeEntry();
    const harness = createHarness(entry, []);

    const result = await undoLastAction(harness.pool, {
      entry,
      userId: 'user-1',
    });

    expect(result).toBeNull();
  });

  it('undoes the most recent completion and syncs next_due_date', async () => {
    const entry = makeEntry();
    const completed = makeOccurrence({
      status: 'completed',
      completed_on: new Date('2026-09-01'),
      completion_timing: 'on_time',
      marked_at: new Date('2026-09-01T12:00:00Z'),
      marked_by_user_id: 'user-1',
      notes: 'Done',
    });
    const harness = createHarness(entry, [completed]);

    const result = await undoLastAction(harness.pool, {
      entry,
      userId: 'user-1',
    });

    expect(result).not.toBeNull();
    expect(result.actionType).toBe('complete');
    expect(result.occurrence.status).toBe('pending');
    expect(result.occurrence.completed_on).toBeNull();
    expect(result.occurrence.completion_timing).toBeNull();
    expect(harness.occurrences[0].status).toBe('pending');
    expect(result.nextDueDate).toBe('2026-09-01');
  });

  it('undoes skip using ledger timestamp awareness when pause is older', async () => {
    const entry = makeEntry();
    const skipped = makeOccurrence({
      id: 'occ-skipped',
      status: 'skipped',
      marked_at: new Date('2026-09-02T18:00:00Z'),
      marked_by_user_id: 'user-1',
      notes: 'Skipped',
    });
    const ledgerEvents = [
      {
        id: 'evt-pause',
        health_entry_id: entry.id,
        health_occurrence_id: null,
        event_type: 'paused',
        from_date: '2026-09-01',
        occurred_at: new Date('2026-09-01T10:00:00Z'),
      },
      {
        id: 'evt-skipped',
        health_entry_id: entry.id,
        health_occurrence_id: skipped.id,
        event_type: SCHEDULE_EVENT_SKIPPED,
        from_date: '2026-09-01',
        occurred_at: new Date('2026-09-02T18:00:00Z'),
      },
    ];
    const harness = createHarness(entry, [skipped], ledgerEvents);

    const result = await undoLastAction(harness.pool, {
      entry,
      userId: 'user-1',
    });

    expect(result).not.toBeNull();
    expect(result.actionType).toBe('skip');
    expect(result.scheduleEventId).toBe('evt-skipped');
    expect(harness.occurrences[0].status).toBe('pending');
    expect(harness.occurrences[0].notes).toBe('');
  });

  it('prefers newer ledger event over older occurrence closure', async () => {
    const entry = makeEntry({ status: 'paused', paused_since: new Date('2026-09-03') });
    const completed = makeOccurrence({
      status: 'completed',
      marked_at: new Date('2026-09-01T12:00:00Z'),
    });
    const ledgerEvents = [
      {
        id: 'evt-pause',
        health_entry_id: entry.id,
        health_occurrence_id: null,
        event_type: 'paused',
        from_date: '2026-09-03',
        occurred_at: new Date('2026-09-03T09:00:00Z'),
      },
    ];
    const harness = createHarness(entry, [completed], ledgerEvents);
    const baseQuery = harness.pool.query.bind(harness.pool);

    harness.pool.query = async (sql, params) => {
      if (
        sql.includes("UPDATE health_entries SET status = 'active'")
        && sql.includes('paused_since = NULL')
      ) {
        entry.status = 'active';
        entry.paused_since = null;
        return { rows: [{ ...entry }] };
      }
      return baseQuery(sql, params);
    };

    const result = await undoLastAction(harness.pool, {
      entry,
      userId: 'user-1',
    });

    expect(result).not.toBeNull();
    expect(result.actionType).toBe('paused');
    expect(result.scheduleEventId).toBe('evt-pause');
    expect(entry.status).toBe('active');
  });
});
