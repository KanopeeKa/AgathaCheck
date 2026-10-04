/**
 * OpenAPI contract for care items against real responses (D-CIE-028).
 */
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { assertMatchesSchema } from '../../lib/openapi/assertDto.js';
import { loadPetCareCriticalSpec, responseSchema } from '../../lib/openapi/petCareCriticalSpec.js';
import { careApi, createOwner, openStrictHarness, removeOwner } from './helpers/careHarness.js';

const spec = loadPetCareCriticalSpec();
let harness;
let owner;
let api;

function assertResponse(pathKey, method, status, body) {
  const schema = responseSchema(spec, pathKey, method, status);
  if (!schema) throw new Error(`No schema for ${method} ${pathKey} ${status}`);
  assertMatchesSchema(spec, schema, body);
}

beforeAll(async () => {
  harness = await openStrictHarness();
  owner = await createOwner(harness.pool, { timeZone: 'Europe/Paris' });
  api = careApi(harness.app, owner);
}, 30000);

afterAll(async () => {
  if (harness?.pool) {
    await removeOwner(harness.pool, owner);
    await harness.pool.end();
  }
});

describe('care item contract', () => {
  it('GET /health-entries/:id matches CareItem, including a twice-daily stack', async () => {
    const created = await api.at('2026-06-01T07:00').create({
      care_family: 'medication', frequency: 'daily', next_due_date: '2026-06-01', schedule_times: ['08:00', '18:00'],
    });
    const res = await api.at('2026-06-03T19:00').get(created.body.id);
    expect(res.statusCode).toBe(200);
    assertResponse('/health-entries/{id}', 'get', 200, res.body);
    // Payload stays small (review R3): the three-day stack plus the next date.
    expect(res.body.open_occurrences.length).toBeLessThanOrEqual(10);
  });

  it('complete matches CareCommandResponse with no choice sent, and a refused choice matches CareCommandError', async () => {
    const created = await api.at('2026-06-01T07:00').create({
      care_family: 'medication', frequency: 'daily', next_due_date: '2026-06-01', schedule_times: ['08:00', '18:00'],
    });
    const morning = created.body.open_occurrences[0];
    const refused = await api.at('2026-06-01T15:00').complete(created.body.id, morning.id, { next_choice: 'shift_following' });
    expect(refused.statusCode).toBe(400);
    assertResponse('/health-entries/{id}/occurrences/{occId}/complete', 'post', 400, refused.body);
    const done = await api.at('2026-06-01T15:00').complete(created.body.id, morning.id, {});
    expect(done.statusCode).toBe(200);
    expect(done.body.next_choice_applied).toBe('keep');
    assertResponse('/health-entries/{id}/occurrences/{occId}/complete', 'post', 200, done.body);
  });
});

describe('If done after the due date (D2, D-CSM-026 v4)', () => {
  it('create and edit store the remembered choice; an unknown value is refused', async () => {
    const created = await api.at('2026-06-01T07:00').create({
      care_family: 'medication', frequency: 'daily', next_due_date: '2026-06-01',
      schedule_times: ['08:00', '18:00'], late_completion_choice: 'skip_next',
    });
    expect(created.statusCode).toBe(201);
    expect(created.body.late_completion_choice).toBe('skip_next');
    assertResponse('/health-entries/{id}', 'get', 200, created.body);

    const base = {
      name: 'Care', care_family: 'medication', frequency: 'daily', next_due_date: '2026-06-01',
      schedule_times: ['08:00', '18:00'], recurrence_anchor: 'from_due_date',
    };
    const cleared = await api.at('2026-06-01T07:05').put(created.body.id, { ...base, late_completion_choice: null });
    expect(cleared.statusCode).toBe(200);
    expect(cleared.body.late_completion_choice).toBeNull();

    const refused = await api.at('2026-06-01T07:06').put(created.body.id, { ...base, late_completion_choice: 'ask' });
    expect(refused.statusCode).toBe(400);
  });
});
