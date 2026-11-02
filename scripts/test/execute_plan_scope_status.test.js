'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { describeScope, reasonOf, scopeEntryFromStatuses, scopeFailedSince, DESCRIPTION_MAX } = require('../lib/execute_plan_scope_status');

const st = (id, state, description, login = 'github-actions[bot]', created_at = '2026-11-02T10:00:00Z') => ({
  id, context: 'execute-plan-scope', state, description, created_at, updated_at: created_at, creator: { login },
});

test('description carries the reason first and fits GitHub limit', () => {
  assert.equal(describeScope('ok', '\nNo violations.\n- x'), 'ok: No violations.');
  assert.equal(describeScope('drift', ''), 'drift');
  const long = describeScope('unclassified', 'v'.repeat(400));
  assert.equal(long.length, DESCRIPTION_MAX);
  assert.equal(reasonOf(long), 'unclassified');
  assert.equal(reasonOf('plan-stopped: plan stopped: revoked'), 'plan-stopped');
  assert.equal(reasonOf('Free text'), null);
});

test('newest trusted status becomes the checks entry', () => {
  assert.equal(scopeEntryFromStatuses([]), null);
  assert.equal(scopeEntryFromStatuses([st(1, 'success', 'ok', 'pawpet-bot')]), null);
  assert.deepEqual(scopeEntryFromStatuses([st(1, 'failure', 'drift: x'), st(3, 'success', 'ok: y'), st(2, 'error', 'z', 'pawpet-bot')]), {
    name: 'execute-plan-scope', status: 'completed', conclusion: 'success', reason: 'ok', completed_at: '2026-11-02T10:00:00Z',
  });
  assert.equal(scopeEntryFromStatuses([st(1, 'error', 'x')]).conclusion, 'failure');
  assert.deepEqual(scopeEntryFromStatuses([st(1, 'pending', 'ok')]).status, 'in_progress');
});

test('failed since epoch ignores untrusted and older statuses', () => {
  const epoch = '2026-11-02T09:00:00Z';
  assert.equal(scopeFailedSince([st(1, 'failure', 'x', 'pawpet-bot')], epoch), false);
  assert.equal(scopeFailedSince([st(1, 'failure', 'x', undefined, '2026-11-02T08:00:00Z')], epoch), false);
  assert.equal(scopeFailedSince([st(1, 'success', 'ok'), st(2, 'failure', 'x')], epoch), true);
});
