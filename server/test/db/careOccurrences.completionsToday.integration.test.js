/**
 * `completions_today` on care item list/detail reads (pet home calendar).
 */
import { afterAll, describe, expect, it } from '@jest/globals';

import { assertMatchesSchema } from '../../lib/openapi/assertDto.js';
import { loadPetCareCriticalSpec, responseSchema } from '../../lib/openapi/petCareCriticalSpec.js';
import { careApi, createOwner, openStrictHarness, removeOwner } from './helpers/careHarness.js';

const spec = loadPetCareCriticalSpec();
let harness;

function assertCareItem(body) {
  const schema = responseSchema(spec, '/health-entries/{id}', 'get', 200);
  assertMatchesSchema(spec, schema, body);
}

afterAll(async () => {
  if (harness?.pool) await harness.pool.end();
});

describe('completions_today', () => {
  it('lists same-day doses and excludes other calendar days (Europe/Paris)', async () => {
    harness = await openStrictHarness();
    const owner = await createOwner(harness.pool, { timeZone: 'Europe/Paris' });
    const api = careApi(harness.app, owner);
    try {
      const created = await api.at('2026-06-01T07:00').create({
        care_family: 'medication',
        frequency: 'daily',
        next_due_date: '2026-06-01',
        schedule_times: ['08:00', '18:00'],
      });
      const morning = created.body.open_occurrences.find((o) => o.scheduled_time === '08:00');
      const evening = created.body.open_occurrences.find((o) => o.scheduled_time === '18:00');
      await api.at('2026-06-01T15:00').complete(created.body.id, morning.id, {});
      let item = (await api.at('2026-06-01T15:05').get(created.body.id)).body;
      expect(item.completions_today).toHaveLength(1);
      expect(item.completions_today[0]).toMatchObject({
        occurrence_id: morning.id,
        scheduled_date: '2026-06-01',
        scheduled_time: '08:00',
        completed_on: '2026-06-01',
        time: expect.stringMatching(/^\d{2}:\d{2}$/),
      });
      assertCareItem(item);

      await api.at('2026-06-01T19:30').complete(created.body.id, evening.id, {});
      item = (await api.at('2026-06-01T19:35').get(created.body.id)).body;
      expect(item.completions_today.map((c) => c.scheduled_time)).toEqual(['08:00', '18:00']);
      assertCareItem(item);

      await api.at('2026-06-02T08:00').complete(created.body.id, item.open_occurrences[0].id, {});
      item = (await api.at('2026-06-02T08:05').get(created.body.id)).body;
      expect(item.completions_today).toHaveLength(1);
      expect(item.completions_today[0].completed_on).toBe('2026-06-02');
      expect(item.completions_today[0].scheduled_date).toBe('2026-06-02');
    } finally {
      await removeOwner(harness.pool, owner);
    }
  });

  it('keys off completed_on versus as_of.date (pet home calendar)', async () => {
    harness = await openStrictHarness();
    const owner = await createOwner(harness.pool, { timeZone: 'Europe/Paris' });
    const api = careApi(harness.app, owner);
    try {
      const created = await api.at('2026-06-01T07:00').create({
        care_family: 'parasite_prevention',
        frequency: 'monthly',
        next_due_date: '2026-06-05',
      });
      const occ = created.body.open_occurrences[0];
      await api
        .at('2026-06-02T10:00')
        .complete(created.body.id, occ.id, { completed_on: '2026-06-01' });
      let item = (await api.at('2026-06-02T10:05').get(created.body.id)).body;
      expect(item.as_of.date).toBe('2026-06-02');
      expect(item.completions_today).toEqual([]);

      item = (await api.at('2026-06-01T23:00').get(created.body.id)).body;
      expect(item.as_of).toMatchObject({ date: '2026-06-01', timezone: 'Europe/Paris' });
      expect(item.completions_today).toHaveLength(1);
      expect(item.completions_today[0].completed_on).toBe('2026-06-01');
      assertCareItem(item);
    } finally {
      await removeOwner(harness.pool, owner);
    }
  });
});
