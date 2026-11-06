'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { qualifiesOwnerScopeAck, findOwnerScopeAckReview } = require('../lib/execute_plan_scope_ack');

const HEAD = 'a'.repeat(40);
const owners = ['KanopeeKa'];
const bot = 'pawpet-bot';

test('qualifiesOwnerScopeAck requires APPROVED review on head by configured owner', () => {
  const ok = { state: 'APPROVED', commit_id: HEAD, user: { login: 'KanopeeKa' }, id: 2 };
  assert.equal(qualifiesOwnerScopeAck(ok, { headSha: HEAD, owners, botLogin: bot }), true);
  assert.equal(qualifiesOwnerScopeAck({ ...ok, commit_id: 'b'.repeat(40) }, { headSha: HEAD, owners, botLogin: bot }), false);
  assert.equal(qualifiesOwnerScopeAck({ ...ok, state: 'CHANGES_REQUESTED' }, { headSha: HEAD, owners, botLogin: bot }), false);
  assert.equal(qualifiesOwnerScopeAck({ ...ok, user: { login: 'stranger' } }, { headSha: HEAD, owners, botLogin: bot }), false);
  assert.equal(qualifiesOwnerScopeAck({ ...ok, user: { login: bot } }, { headSha: HEAD, owners, botLogin: bot }), false);
});

test('findOwnerScopeAckReview picks the newest qualifying review', () => {
  const reviews = [
    { id: 1, state: 'APPROVED', commit_id: HEAD, user: { login: 'KanopeeKa' } },
    { id: 3, state: 'APPROVED', commit_id: HEAD, user: { login: 'KanopeeKa' } },
    { id: 2, state: 'APPROVED', commit_id: 'b'.repeat(40), user: { login: 'KanopeeKa' } },
  ];
  assert.equal(findOwnerScopeAckReview(reviews, { headSha: HEAD, owners, botLogin: bot }).id, 3);
});

test('findOwnerScopeAckReview ignores stale approval after CHANGES_REQUESTED', () => {
  const reviews = [
    { id: 1, state: 'APPROVED', commit_id: HEAD, user: { login: 'KanopeeKa' } },
    { id: 2, state: 'CHANGES_REQUESTED', commit_id: HEAD, user: { login: 'KanopeeKa' } },
  ];
  assert.equal(findOwnerScopeAckReview(reviews, { headSha: HEAD, owners, botLogin: bot }), null);
});
