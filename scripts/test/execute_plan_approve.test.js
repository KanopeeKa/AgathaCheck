'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { buildSnapshotFromPlan } = require('../lib/execute_plan_snapshot_v2');
const { formatStatusComment } = require('../lib/execute_plan_status');
const { handleControlComment } = require('../lib/execute_plan_approve');

const PLAN_ID = 'proof-build-label-7f3a';
const PLAN_MD = `# Proof

## Goal
x

## Phases

### Phase 1 — First
\`\`\`json
{ "allowed_paths": ["a/**"], "exit_checklist": ["ok"] }
\`\`\`

## Proof on UAT
y
`;
const SNAP = buildSnapshotFromPlan({ planId: PLAN_ID, planMarkdown: PLAN_MD, controlIssue: 9, now: '2026-10-16T09:00:30Z' });
const CONFIG = { owners: ['KanopeeKa'], bot_login: 'pawpet-bot', uat: {} };
const SHA = 'a'.repeat(40);
const NOW = '2026-10-16T10:00:00Z';
const PLAN_FILES = [SNAP.plan_file, `.agents/plans/${PLAN_ID}.snapshot.json`];
const APPROVE = `approve-autonomous ${PLAN_ID} ${SNAP.approval_hash} until ${SNAP.approved_until}`;
const RESUME = `resume-autonomous ${PLAN_ID} ${SNAP.approval_hash} until 2026-10-20T10:00:00Z`;
const REVOKE = `revoke-autonomous ${PLAN_ID}`;

const issueBody = `Plan: x\n\nInit branch: cursor/${PLAN_ID}-init @ ${SHA}\n`;
const mkIssue = (labels = ['execute-plan'], body = issueBody) => ({ number: 9, body, labels: labels.map((name) => ({ name })) });
const mkComment = (body, over = {}) => ({
  id: 4242, body, user: { login: 'KanopeeKa' }, author_association: 'OWNER',
  created_at: '2026-10-16T09:59:00Z', updated_at: '2026-10-16T09:59:00Z', ...over,
});
const event = (comment, over = {}) => ({ action: 'created', issue: mkIssue(), comment, ...over });

function setup({ files = PLAN_FILES, integration = null, issueComments = [], snapshotAtSha = SNAP } = {}) {
  const writes = [];
  const rec = (kind) => async (...args) => { writes.push([kind, ...args]); return {}; };
  const read = {
    getFileAtRef: async (path, ref) => {
      if (path.endsWith('execute-plan.config.json')) return { content: JSON.stringify(CONFIG), sha: 's' };
      if (ref !== SHA) return null;
      return { content: path.endsWith('.json') ? JSON.stringify(snapshotAtSha) : PLAN_MD, sha: 's' };
    },
    compare: async () => ({ files: files.map((filename) => ({ filename })) }),
    getBranch: async () => integration,
  };
  const bot = {
    createRef: rec('createRef'),
    createComment: rec('createComment'),
    addLabels: rec('addLabels'),
    updateIssue: rec('updateIssue'),
    listIssueComments: async () => issueComments,
  };
  const passes = [];
  const deps = {
    loadPlanContext: async (_c, args) => { passes.push(['load', args.planId]); return { planId: PLAN_ID, issueNumber: 9, snapshot: SNAP, config: CONFIG, status: { lease: null }, statusComment: { id: 1 } }; },
    tick: async () => ({ state: 'phase:pending', phase: '1', action: { actor: 'driver', kind: 'wait', args: { reason: 'checks' } }, stop: null }),
  };
  return { clients: { bot, read, cursorApiKey: null, deps }, writes, passes };
}
const run = (s, ev, killSwitch = 'on') => handleControlComment(s.clients, ev, { now: NOW, killSwitch });
const kinds = (s) => s.writes.map((w) => w[0]);

test('valid approve → branch, status comment, labels, approval line, driver pass', async () => {
  const s = setup();
  const res = await run(s, event(mkComment(APPROVE)));
  assert.deepEqual(res, { handled: true, detail: 'driver pass run' });
  assert.deepEqual(s.writes[0], ['createRef', `refs/heads/${SNAP.integration_branch}`, SHA]);
  const [, , statusBody] = s.writes.find((w) => w[0] === 'createComment');
  assert.match(statusBody, new RegExp(`^<!-- execute-plan-status:${PLAN_ID} -->`));
  assert.match(statusBody, new RegExp(`"init_sha": "${SHA}"`));
  assert.match(statusBody, /"state": "phase:pending"/);
  assert.deepEqual(s.writes.find((w) => w[0] === 'addLabels'), ['addLabels', 9, ['autonomous-approved', `plan:${PLAN_ID}`]]);
  const [, , patch] = s.writes.find((w) => w[0] === 'updateIssue');
  assert.match(patch.body, /Approval: valid \(comment 4242\)$/);
  assert.deepEqual(s.passes, [['load', PLAN_ID]]);
  assert.ok(kinds(s).indexOf('createRef') < kinds(s).indexOf('addLabels'));
});

test('approve is idempotent: branch already at the init sha, status comment present, line present', async () => {
  const status = formatStatusComment({ plan_id: PLAN_ID, init_sha: SHA }, '');
  const s = setup({ integration: { commit: { sha: SHA } }, issueComments: [{ body: status, user: { login: 'pawpet-bot' } }] });
  const ev = event(mkComment(APPROVE), { issue: mkIssue(['execute-plan'], `${issueBody}\nApproval: valid (comment 4242)`) });
  const res = await run(s, ev);
  assert.equal(res.handled, true);
  assert.deepEqual(kinds(s), ['addLabels']);
});

test('a status-looking comment from someone else does not count as the status comment', async () => {
  const status = formatStatusComment({ plan_id: PLAN_ID, init_sha: SHA }, '');
  const s = setup({ issueComments: [{ body: status, user: { login: 'mallory' } }] });
  await run(s, event(mkComment(APPROVE)));
  assert.ok(kinds(s).includes('createComment'));
});

test('approve: integration branch at another sha → rejected', async () => {
  const s = setup({ integration: { commit: { sha: 'b'.repeat(40) } } });
  const res = await run(s, event(mkComment(APPROVE)));
  assert.equal(res.handled, true);
  assert.deepEqual(kinds(s), ['createComment']);
  assert.match(s.writes[0][2], /^approve-autonomous rejected: integration branch .* already exists/);
});

test('not owner → ignored, no comment', async () => {
  for (const over of [{ user: { login: 'mallory' } }, { author_association: 'CONTRIBUTOR' }, { user: { login: 'pawpet-bot' } }]) {
    const s = setup();
    const res = await run(s, event(mkComment(APPROVE, over)));
    assert.equal(res.handled, false);
    assert.deepEqual(s.writes, []);
  }
});

test('invalid hash → exactly one rejected comment, nothing else', async () => {
  const s = setup();
  const bad = APPROVE.replace(/sha256:[0-9a-f]{4}/, 'sha256:0000');
  const res = await run(s, event(mkComment(bad)));
  assert.equal(res.handled, true);
  assert.deepEqual(s.writes, [['createComment', 9, 'approve-autonomous rejected: hash']]);
  assert.deepEqual(s.passes, []);
});

test('approve with a wrong until is rejected', async () => {
  const wrongUntil = APPROVE.replace(/until .*$/, 'until 2030-01-01T00:00:00Z');
  const s = setup();
  await run(s, event(mkComment(wrongUntil)));
  assert.equal(s.writes[0][2], 'approve-autonomous rejected: until');
});

test('init branch with extra files → rejected', async () => {
  const s = setup({ files: [...PLAN_FILES, 'server/evil.js'] });
  await run(s, event(mkComment(APPROVE)));
  assert.deepEqual(kinds(s), ['createComment']);
  assert.match(s.writes[0][2], /exactly the two plan files \(found: .*server\/evil\.js\)/);
});

test('init branch with only one plan file → rejected', async () => {
  const s = setup({ files: [PLAN_FILES[0]] });
  await run(s, event(mkComment(APPROVE)));
  assert.match(s.writes[0][2], /exactly the two plan files/);
});

test('missing Init branch line or a snapshot that is not at the sha → rejected', async () => {
  const s = setup();
  await run(s, event(mkComment(APPROVE), { issue: mkIssue(['execute-plan'], 'no line') }));
  assert.match(s.writes[0][2], /no "Init branch/);
  const other = setup();
  const body = `Init branch: cursor/${PLAN_ID}-init @ ${'c'.repeat(40)}`;
  await run(other, event(mkComment(APPROVE), { issue: mkIssue(['execute-plan'], body) }));
  assert.match(other.writes[0][2], /not found at/);
});

test('comments on PRs and on issues without the execute-plan label are ignored', async () => {
  const s = setup();
  assert.equal((await run(s, event(mkComment(APPROVE), { issue: { ...mkIssue(), pull_request: {} } }))).handled, false);
  assert.equal((await run(s, event(mkComment(APPROVE), { issue: mkIssue(['bug']) }))).handled, false);
  assert.equal((await run(s, event(mkComment('hello')))).handled, false);
  assert.deepEqual(s.writes, []);
});

test('resume (valid) → one driver pass and no other write', async () => {
  const s = setup();
  const res = await run(s, event(mkComment(RESUME), { issue: mkIssue(['execute-plan', 'autonomous-approved', `plan:${PLAN_ID}`]) }));
  assert.equal(res.handled, true);
  assert.deepEqual(s.writes, []);
  assert.equal(s.passes.length, 2); // approvedContext + the pass
});

test('resume: invalid or on an unapproved issue → no pass', async () => {
  const approved = mkIssue(['execute-plan', 'autonomous-approved', `plan:${PLAN_ID}`]);
  const s = setup();
  const tooLong = RESUME.replace(/until .*$/, 'until 2027-01-01T00:00:00Z');
  const res = await run(s, event(mkComment(tooLong), { issue: approved }));
  assert.match(res.detail, /invalid resume: window/);
  const unapproved = await run(s, event(mkComment(RESUME)));
  assert.equal(unapproved.detail, 'issue not approved');
  assert.deepEqual(s.writes, []);
  assert.deepEqual(s.passes, [['load', PLAN_ID]]);
});

test('revoke (valid) → label autonomous-revoked then a driver pass; not owner → nothing', async () => {
  const approved = mkIssue(['execute-plan', 'autonomous-approved', `plan:${PLAN_ID}`]);
  const s = setup();
  const res = await run(s, event(mkComment(REVOKE), { issue: approved }));
  assert.equal(res.handled, true);
  assert.deepEqual(s.writes, [['addLabels', 9, ['autonomous-revoked']]]);
  const other = setup();
  await run(other, event(mkComment(REVOKE, { user: { login: 'mallory' } }), { issue: approved }));
  assert.deepEqual(other.writes, []);
});

test('edited / deleted approve or resume → one driver pass; revoke edits and unapproved issues → none', async () => {
  const approved = mkIssue(['execute-plan', 'autonomous-approved', `plan:${PLAN_ID}`]);
  for (const action of ['edited', 'deleted']) {
    for (const body of [APPROVE, RESUME]) {
      const s = setup();
      const res = await run(s, event(mkComment(body), { action, issue: approved }));
      assert.equal(res.handled, true);
      assert.deepEqual(s.passes, [['load', PLAN_ID]]);
      assert.deepEqual(s.writes, []);
    }
  }
  const revoke = setup();
  assert.equal((await run(revoke, event(mkComment(REVOKE), { action: 'edited', issue: approved }))).handled, false);
  const unapproved = setup();
  assert.equal((await run(unapproved, event(mkComment(APPROVE), { action: 'edited' }))).handled, false);
  assert.deepEqual(unapproved.passes.concat(revoke.passes), []);
});

test('kill switch off → no-op; dry-run → validates, no writes', async () => {
  const off = setup();
  const res = await run(off, event(mkComment(APPROVE)), 'off');
  assert.deepEqual([res.handled, off.writes, off.passes], [false, [], []]);
  const unset = setup();
  assert.equal((await handleControlComment(unset.clients, event(mkComment(APPROVE)), { now: NOW })).handled, false);
  assert.deepEqual(unset.writes, []);

  const dry = setup();
  const dryRes = await run(dry, event(mkComment(APPROVE)), 'dry-run');
  assert.equal(dryRes.handled, false);
  assert.deepEqual(dry.writes, []);
  assert.deepEqual(dry.passes, [], 'approve in dry-run stops after validation');

  const dryBad = setup();
  await run(dryBad, event(mkComment(APPROVE.replace(/sha256:[0-9a-f]{4}/, 'sha256:0000'))), 'dry-run');
  assert.deepEqual(dryBad.writes, [], 'dry-run does not even post the rejection');

  const dryRevoke = setup();
  const approved = mkIssue(['execute-plan', 'autonomous-approved', `plan:${PLAN_ID}`]);
  await run(dryRevoke, event(mkComment(REVOKE), { issue: approved }), 'dry-run');
  assert.deepEqual(dryRevoke.writes, []);
});
