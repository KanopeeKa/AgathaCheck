/**
 * CARE-STATUS-R-020, R-023 — closed item wire and read-only command guard.
 */
import { randomUUID } from 'crypto';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import {
  careApi,
  createOwner,
  openStrictHarness,
  removeOwner,
} from './helpers/careHarness.js';

describe('care item closed status', () => {
  /** @type {import('pg').Pool|null} */
  let pool;
  /** @type {import('express').Express|null} */
  let app;
  let owner;
  let api;
  let entryId;

  beforeAll(async () => {
    const harness = await openStrictHarness();
    pool = harness.pool;
    app = harness.app;
    owner = await createOwner(pool);
    api = careApi(app, owner);
    entryId = randomUUID();
    await pool.query(
      `INSERT INTO health_entries
         (id, pet_id, user_id, name, type, frequency, status, care_planning, care_importance,
          care_closed_reason, start_date, completed_on)
       VALUES ($1, $2, $3, 'Old care', 'medication', 'once', 'closed', 'planned', 'essential',
         'ended', CURRENT_DATE - 30, CURRENT_DATE - 30)`,
      [entryId, owner.petId, owner.userId],
    );
  });

  afterAll(async () => {
    if (!pool) return;
    if (entryId) {
      await pool.query('DELETE FROM health_entries WHERE id = $1', [entryId]);
    }
    if (owner) await removeOwner(pool, owner);
    await pool.end();
  });

  it('GET detail exposes closed status and empty open occurrences', async () => {
    if (!app) return;
    const res = await api.get(entryId);
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('closed');
    expect(res.body.care_closed_reason).toBe('ended');
    expect(res.body.open_occurrences).toEqual([]);
  });

  it('POST reopen route is removed', async () => {
    if (!app) return;
    const res = await api.reopen(entryId);
    expect(res.statusCode).toBe(404);
  });

  it('POST schedule undo is rejected when care is closed (R-011)', async () => {
    if (!app) return;
    const res = await api.undo(entryId);
    expect(res.statusCode).toBe(409);
    expect(res.body.code).toBe('care_item_closed');
  });

  it('undo after Close care does not reopen stopped_by_user items (R-011)', async () => {
    if (!app) return;
    const created = await api.at('2026-06-01T09:00').create({
      name: 'Flea',
      care_family: 'parasite_prevention',
      frequency: 'monthly',
      next_due_date: '2026-06-05',
    });
    expect(created.statusCode).toBe(201);
    const entry = created.body;
    const occId = entry.open_occurrences[0].id;
    const done = await api.at('2026-06-05T10:00').complete(entry.id, occId, {});
    expect(done.statusCode).toBe(200);
    const closed = await api.at('2026-06-05T10:01').close(entry.id);
    expect(closed.body.status).toBe('closed');
    expect(closed.body.care_closed_reason).toBe('stopped_by_user');
    const undone = await api.at('2026-06-05T10:02').undo(entry.id, { undo_token: done.body.undo_token });
    expect(undone.statusCode).toBe(409);
    expect(undone.body.code).toBe('care_item_closed');
  });
});
