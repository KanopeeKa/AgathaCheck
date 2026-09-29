/**
 * OpenAPI contract for care items against real responses (D-CIE-028).
 */
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { assertMatchesSchema } from '../../lib/openapi/assertDto.js';
import { loadPetCareCriticalSpec, responseSchema } from '../../lib/openapi/petCareCriticalSpec.js';
import { careApi, createOwner, openHarness, removeOwner } from './helpers/careHarness.js';

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
  harness = await openHarness();
  if (!harness.pool) return;
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
    if (!harness.pool) return;
    const created = await api.at('2026-06-01T07:00').create({
      care_family: 'medication', frequency: 'daily', next_due_date: '2026-06-01', schedule_times: ['08:00', '18:00'],
    });
    const res = await api.at('2026-06-03T19:00').get(created.body.id);
    expect(res.statusCode).toBe(200);
    assertResponse('/health-entries/{id}', 'get', 200, res.body);
    // Payload stays small (review R3): the three-day stack plus the next date.
    expect(res.body.open_occurrences.length).toBeLessThanOrEqual(10);
  });

  it('complete matches CareCommandResponse, and the 409 matches NextChoiceRequired', async () => {
    if (!harness.pool) return;
    const created = await api.at('2026-06-01T07:00').create({
      care_family: 'vaccination', frequency: 'yearly', next_due_date: '2026-06-01', planned_dates: ['2026-07-01'],
    });
    const first = created.body.open_occurrences[0];
    const ask = await api.at('2026-06-25T09:00').complete(created.body.id, first.id, {});
    expect(ask.statusCode).toBe(409);
    assertResponse('/health-entries/{id}/occurrences/{occId}/complete', 'post', 409, ask.body);
    const done = await api.at('2026-06-25T09:00').complete(created.body.id, first.id, { next_choice: 'keep' });
    expect(done.statusCode).toBe(200);
    assertResponse('/health-entries/{id}/occurrences/{occId}/complete', 'post', 200, done.body);
  });
});
