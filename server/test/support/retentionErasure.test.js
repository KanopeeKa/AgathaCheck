import { v4 as uuidv4 } from 'uuid';

import { jest, describe, expect, it } from '@jest/globals';

import { buildSupportScreenshotStorageKey } from '../../lib/support/screenshots/storage.js';
import { purgeSupportTickets } from '../../lib/support/retention/purgeTickets.js';
import { purgeSupportTicketsForAccountErasure } from '../../lib/support/retention/erasureForUser.js';
import { maybeRunDailySupportRetention } from '../../lib/support/retention/dailyScheduler.js';
import { SUPPORT_RETENTION_JOB_KEY } from '../../lib/support/retention/constants.js';

function utcDayKey(date = new Date()) {
  return date.toISOString().slice(0, 10);
}

describe('purgeSupportTickets', () => {
  it('enqueues file deletes and redact rows then deletes tickets', async () => {
    const ticketId = uuidv4();
    const storageKey = buildSupportScreenshotStorageKey('shot-a.png');
    const queries = [];

    const client = {
      query: jest.fn(async (sql, params) => {
        queries.push({ sql, params });
        if (sql.includes('FROM support_attachments')) {
          return { rows: [{ id: uuidv4(), storage_key: storageKey }] };
        }
        if (sql.includes('FROM support_tickets') && sql.includes('github_issue_number')) {
          return { rows: [{ id: ticketId, github_issue_number: 99 }] };
        }
        if (sql.startsWith('INSERT INTO cleanup_jobs')) {
          return { rows: [{ id: uuidv4() }] };
        }
        if (sql.includes('INSERT INTO support_outbox')) {
          return { rows: [{ id: uuidv4() }] };
        }
        if (sql.startsWith('DELETE FROM support_outbox')) {
          return { rowCount: 2 };
        }
        if (sql.startsWith('DELETE FROM support_tickets')) {
          return { rowCount: 1 };
        }
        return { rows: [], rowCount: 0 };
      }),
    };

    const opId = uuidv4();
    const result = await purgeSupportTickets(client, [ticketId], opId);

    expect(result.ticketIds).toEqual([ticketId]);
    expect(result.issueNumbers).toEqual([99]);
    expect(result.attachmentPaths).toEqual(['shot-a.png']);

    const fileJob = queries.find((q) => q.sql.includes('INSERT INTO cleanup_jobs'));
    expect(fileJob).toBeTruthy();
    expect(JSON.parse(fileJob.params[4]).relative_path).toBe('shot-a.png');
    expect(fileJob.params[3]).toBe(opId);

    const redact = queries.find((q) => q.sql.includes('github_issue_delete'));
    expect(redact?.params).toEqual(expect.arrayContaining([99]));

    expect(queries.some((q) => q.sql.startsWith('DELETE FROM support_tickets'))).toBe(true);
  });
});

describe('purgeSupportTicketsForAccountErasure', () => {
  it('selects signed-in and normalised signed-out tickets', async () => {
    const signedOutId = uuidv4();
    const userId = uuidv4();
    const client = {
      query: jest.fn(async (sql, params) => {
        if (sql.includes('SELECT id FROM support_tickets')) {
          expect(params[1]).toBe('user@example.com');
          return { rows: [{ id: signedOutId }] };
        }
        if (sql.includes('FROM support_attachments')) {
          return { rows: [] };
        }
        if (sql.includes('github_issue_number')) {
          return { rows: [{ id: signedOutId, github_issue_number: 12 }] };
        }
        if (sql.includes('github_issue_delete')) {
          return { rows: [{ id: uuidv4() }] };
        }
        if (sql.startsWith('DELETE FROM')) {
          return { rowCount: 1 };
        }
        return { rows: [] };
      }),
    };

    const result = await purgeSupportTicketsForAccountErasure(client, {
      userId,
      userEmail: 'User+tag@Example.com',
      operationId: uuidv4(),
    });

    expect(result.issueNumbers).toEqual([12]);
    expect(client.query.mock.calls[0][1][0]).toBe(userId);
  });
});

describe('maybeRunDailySupportRetention', () => {
  it('claims scheduler_daily_runs once per UTC day', async () => {
    const day = utcDayKey();
    const queries = [];
    const pool = {
      query: jest.fn(async (sql, params) => {
        queries.push({ sql, params });
        if (sql.includes('INSERT INTO scheduler_daily_runs')) {
          return { rows: [{ job_key: SUPPORT_RETENTION_JOB_KEY }] };
        }
        if (sql.includes('FROM support_attachments')) {
          return { rows: [] };
        }
        if (sql.includes('FROM support_tickets') && sql.includes('12 months')) {
          return { rows: [] };
        }
        if (sql.includes('completed_at = NOW()')) {
          return { rows: [{ job_key: SUPPORT_RETENTION_JOB_KEY }] };
        }
        if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
          return { rows: [] };
        }
        return { rows: [] };
      }),
    };

    const result = await maybeRunDailySupportRetention(pool);
    expect(result.skipped).toBe(false);
    const insert = queries.find((q) => q.sql.includes('INSERT INTO scheduler_daily_runs'));
    expect(insert?.params).toEqual([SUPPORT_RETENTION_JOB_KEY, day]);
  });
});
