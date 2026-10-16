'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  APPROVE_RE, canonical, computeApprovalHash, findControlComments, parseControlComment, validateControlComment,
} = require('../lib/execute_plan_approval');

const HEX = 'f'.repeat(64);
const SNAP = {
  plan_id: 'proof-build-label-7f3a',
  approved_until: '2026-10-23T09:00:00Z',
  approval_hash: `sha256:${HEX}`,
};
const CONFIG = { owners: ['KanopeeKa'], bot_login: 'pawpet-bot' };
const line = (verb = 'approve', until = SNAP.approved_until) => `${verb}-autonomous ${SNAP.plan_id} sha256:${HEX} until ${until}`;
function comment(over = {}) {
  return {
    id: 1, user: { login: 'KanopeeKa' }, author_association: 'OWNER',
    created_at: '2026-10-16T09:05:00Z', updated_at: '2026-10-16T09:05:00Z', body: line(), ...over,
  };
}
const check = (c, snapshot = SNAP) => validateControlComment({ comment: c, snapshot, config: CONFIG });

// contracts §3.1 example (illustrative plan_file_sha256), minus approval_hash
const SPEC_OBJECT = {
  schema_version: 2, plan_id: 'proof-build-label-7f3a', title: 'Proof run: UAT build label',
  plan_file: '.agents/plans/proof-build-label-7f3a.md',
  plan_file_sha256: '3b1f0d7c1a4e2f9b8c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b',
  release_branch: 'main', integration_branch: 'cursor/proof-build-label-7f3a-integration-7f3a',
  control_issue: 1900, created_at: '2026-10-16T09:00:00Z', approved_until: '2026-10-23T09:00:00Z',
  settings: { release_owner_review: false, tier3_blocking: false, budgets: { ci_per_phase: 3, launches_per_phase: 5, remedial_rounds: 3, sync_attempts: 2, daily_launches: 20 } },
  protected_paths_version: 1,
  phases: [
    { id: '1', title: 'Server build label', branch: 'cursor/proof-build-label-7f3a-p1', allowed_paths: ['server/bin/server.js', 'server/test/healthProofLabel.test.js'], forbidden_paths: [], allowed_exceptions: ['tests'], companions: [], exit_checklist: ['health test green'] },
    { id: '2', title: 'Docs note', branch: 'cursor/proof-build-label-7f3a-p2', allowed_paths: ['docs/e2e/uat-deploy-tiers.md'], forbidden_paths: [], allowed_exceptions: ['docs'], companions: [], exit_checklist: ['docs gate green'] },
  ],
};

test('canonical empty', () => {
  assert.equal(canonical({}), '{}');
  assert.equal(computeApprovalHash({}), 'sha256:44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a');
});

test('canonical sorted', () => {
  const v = { b: 1, a: [true, null, 'x'] };
  assert.equal(canonical(v), '{"a":[true,null,"x"],"b":1}');
  assert.equal(computeApprovalHash(v), 'sha256:54a65415ad370228851a1da4b31b6fd42dc58b19a50d35cae759325f7388ce64');
});

test('approval hash example (contracts §3.4 vector 3)', () => {
  const canon = canonical(SPEC_OBJECT);
  assert.equal(Buffer.byteLength(canon), 1136);
  assert.ok(canon.startsWith('{"approved_until":"2026-10-23T09:00:00Z","control_issue":1900,'));
  assert.equal(computeApprovalHash(SPEC_OBJECT), 'sha256:fdaabc2824a1c11fc508b1425b7ab18ab5d0abd639794298535fcf43845b1e53');
});

test('hash ignores approval_hash field', () => {
  assert.equal(computeApprovalHash({ ...SPEC_OBJECT, approval_hash: 'sha256:x' }), computeApprovalHash(SPEC_OBJECT));
});

test('hash changes when plan_file_sha256 changes', () => {
  assert.notEqual(computeApprovalHash({ ...SPEC_OBJECT, plan_file_sha256: '0'.repeat(64) }), computeApprovalHash(SPEC_OBJECT));
});

test('approve regex accepts exact line', () => {
  assert.ok(APPROVE_RE.test(line()));
  assert.deepEqual(parseControlComment(`  ${line()}\n`), { verb: 'approve', plan: SNAP.plan_id, hash: HEX, until: SNAP.approved_until });
});

test('approve regex rejects trailing text', () => {
  assert.equal(parseControlComment(`${line()} thanks`), null);
  assert.equal(parseControlComment(`${line()}\nmore`), null);
});

test('resume and revoke parse', () => {
  assert.equal(parseControlComment(line('resume')).verb, 'resume');
  assert.deepEqual(parseControlComment(`revoke-autonomous ${SNAP.plan_id}`), { verb: 'revoke', plan: SNAP.plan_id });
});

test('validate: valid approve', () => {
  assert.deepEqual(check(comment()), { valid: true, reason: null, verb: 'approve', until: SNAP.approved_until });
});

test('validate: not-owner', () => {
  assert.equal(check(comment({ user: { login: 'someone' } })).reason, 'not-owner');
});

test('validate: author_association not OWNER', () => {
  assert.equal(check(comment({ author_association: 'MEMBER' })).reason, 'not-owner');
});

test('validate: bot login', () => {
  const res = validateControlComment({ comment: comment({ user: { login: 'pawpet-bot' } }), snapshot: SNAP, config: { owners: ['pawpet-bot'], bot_login: 'pawpet-bot' } });
  assert.equal(res.reason, 'bot');
});

test('validate: edited', () => {
  assert.equal(check(comment({ updated_at: '2026-10-16T09:06:00Z' })).reason, 'edited');
});

test('validate: wrong plan', () => {
  assert.equal(check(comment({ body: line().replace(SNAP.plan_id, 'other-plan') })).reason, 'plan');
});

test('validate: wrong hash', () => {
  assert.equal(check(comment({ body: line().replace(HEX, 'a'.repeat(64)) })).reason, 'hash');
});

test('validate: approve until mismatch', () => {
  assert.equal(check(comment({ body: line('approve', '2026-10-24T09:00:00Z') })).reason, 'until');
});

test('validate: until must be after the comment', () => {
  assert.equal(check(comment({ body: line('resume', '2026-10-16T09:00:00Z') })).reason, 'until');
});

test('validate: resume until beyond 14 days', () => {
  assert.equal(check(comment({ body: line('resume', '2026-10-30T09:05:01Z') })).reason, 'window');
  assert.equal(check(comment({ body: line('resume', '2026-10-30T09:05:00Z') })).valid, true);
});

test('validate: revoke by owner is valid', () => {
  assert.equal(check(comment({ body: `revoke-autonomous ${SNAP.plan_id}` })).valid, true);
});

test('findControlComments picks latest authorizing', () => {
  const comments = [
    comment({ id: 3, created_at: '2026-10-18T09:00:00Z', updated_at: '2026-10-18T09:00:00Z', body: line('resume', '2026-10-25T09:00:00Z') }),
    comment({ id: 1 }),
    comment({ id: 2, created_at: '2026-10-17T09:00:00Z', updated_at: '2026-10-17T09:00:00Z', body: `revoke-autonomous ${SNAP.plan_id}` }),
    comment({ id: 4, user: { login: 'rando' }, created_at: '2026-10-19T09:00:00Z', updated_at: '2026-10-19T09:00:00Z', body: `revoke-autonomous ${SNAP.plan_id}` }),
  ];
  const res = findControlComments(comments, SNAP, CONFIG);
  assert.equal(res.authorizing.comment_id, 3);
  assert.equal(res.authorizing.verb, 'resume');
  assert.equal(res.authorizing.valid, true);
  assert.equal(res.revoke_comment_at, '2026-10-17T09:00:00Z');
});

test('findControlComments reports an invalid latest comment', () => {
  const res = findControlComments([comment({ user: { login: 'rando' } })], SNAP, CONFIG);
  assert.equal(res.authorizing.valid, false);
  assert.equal(res.authorizing.invalid_reason, 'not-owner');
  assert.equal(findControlComments([], SNAP, CONFIG).authorizing, null);
});
