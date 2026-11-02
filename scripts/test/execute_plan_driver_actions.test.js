'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { buildSnapshotFromPlan } = require('../lib/execute_plan_snapshot_v2');
const { formatStatusComment, parseStatusComment } = require('../lib/execute_plan_status');
const { GitHubError } = require('../lib/execute_plan_github');
const { runDriverPass, buildHandoffPrompt, normalizeKillSwitch } = require('../lib/execute_plan_driver_actions');
const { plansForEvent } = require('../../.github/scripts/execute-plan-driver');

const PLAN_ID = 'proof-build-label-7f3a';
const PLAN_MD = `# Proof

## Goal
x

## Phases

### Phase 1 — First
\`\`\`json
{ "allowed_paths": ["a/**"], "companions": ["b.md"], "exit_checklist": ["ok"] }
\`\`\`

## Proof on UAT
y
`;
const SNAP = buildSnapshotFromPlan({ planId: PLAN_ID, planMarkdown: PLAN_MD, controlIssue: 9, now: '2026-10-16T09:00:30Z' });
const CONFIG = {
  owners: ['KanopeeKa'], bot_login: 'pawpet-bot', cursor_model_implement: 'model-impl', cursor_model_fix: 'model-fix',
  uat: { preuat_workflow: 'pre-uat-e2e.yml', deploy_workflow: 'deploy-uat.yml' },
};
const NOW = '2026-10-16T10:00:00Z';
const baseStatus = (over = {}) => ({
  schema: 1, plan_id: PLAN_ID, init_sha: 'a'.repeat(40), state: 'phase:pending', phase: '1', lease: null, launches: [],
  dispatched: { preuat_heads: [], deploy_tags: [] }, release: null, uat: null, stop: null, updated_at: '2026-10-16T09:40:00Z', ...over,
});

/** Records every call; `pulls` maps number → pull object. */
function fakeClient(name, { status = baseStatus(), pulls = {}, enableError = null, compareFiles = [], openPulls = [] } = {}) {
  const calls = [];
  let body = formatStatusComment(status, '| table |');
  const rec = (kind) => async (...args) => { calls.push([kind, ...args]); };
  const client = {
    name, repo: 'o/r', calls,
    createRef: rec('createRef'),
    getPull: async (n) => pulls[n],
    getBranch: async (b) => (/-(sync|remedial)-\d+$/.test(b) ? null : { commit: { sha: `sha-of-${b}` } }),
    enableAutoMerge: async (id, method) => { calls.push(['enableAutoMerge', id, method]); if (enableError) throw enableError; },
    disableAutoMerge: rec('disableAutoMerge'),
    mergePull: rec('mergePull'),
    updateBranch: rec('updateBranch'),
    listPulls: async () => openPulls,
    createPull: async (p) => { calls.push(['createPull', p]); return { number: 77 }; },
    compare: async () => ({ files: compareFiles.map((filename) => ({ filename })) }),
    dispatchWorkflow: rec('dispatchWorkflow'),
    listIssueComments: async () => [{ id: 55, body }],
    updateComment: async (id, b) => { calls.push(['updateComment', id]); body = b; },
    addLabels: rec('addLabels'),
  };
  client.statusNow = () => parseStatusComment(body);
  client.bodyNow = () => body;
  return client;
}

function harness(opts = {}, tickResult, extra = {}) {
  const bot = fakeClient('bot', opts);
  const read = fakeClient('read');
  const seen = { tick: [], launch: [], scope: [], scopeRuns: [], leaseQueries: [] };
  const deps = {
    loadPlanContext: async () => ({
      planId: PLAN_ID, issueNumber: 9, snapshot: SNAP, config: CONFIG, planMarkdown: PLAN_MD,
      status: opts.status || baseStatus(), statusComment: { id: 55 },
    }),
    tick: async (_c, args) => { seen.tick.push(args); return { state: 'x', phase: '1', stop: null, evidence: [], budgets: {}, ...tickResult }; },
    getAgentRunStatus: async (a) => { seen.leaseQueries.push(a); return extra.runStatus || 'RUNNING'; },
    launchPlanAgent: async (a) => { seen.launch.push(a); return { agentId: 'bc-1', runId: 'run-1', agentUrl: null }; },
    publishScopeCheck: async (c, a) => { seen.scope.push({ client: c.name, ...a }); },
    publishScopeResult: async (c, { headSha, outcome }) => {
      const final = extra.scopeFinal || outcome;
      seen.scope.push({ client: c.name, headSha, conclusion: final.conclusion, title: final.title, summary: final.summary });
      return final;
    },
    runScopeCheck: async (c, a) => { seen.scopeRuns.push({ client: c.name, ...a }); return { conclusion: 'success', title: 'ok', summary: 'No violations.', planId: PLAN_ID }; },
    completePlan: async () => ({ complete: true }),
  };
  return { bot, read, seen, clients: { bot, read, cursorApiKey: extra.noKey ? null : 'key', botToken: extra.noBotToken ? null : 'bot-secret-token', deps }, log: [] };
}
const drive = (h, over = {}) => runDriverPass(h.clients, { planId: PLAN_ID, now: NOW, killSwitch: 'on', log: (l) => h.log.push(l), ...over });
const driverAction = (kind, args) => ({ action: { actor: 'driver', kind, launch: false, args } });
const agentAction = (kind, args, extra = {}) => ({ action: { actor: 'agent', kind, launch: true, args }, ...extra });

test('kill switch: unset and unknown values mean off, off does nothing', async () => {
  assert.equal(normalizeKillSwitch(undefined), 'off');
  assert.equal(normalizeKillSwitch('ON '), 'on');
  assert.equal(normalizeKillSwitch('dry-run'), 'dry-run');
  assert.equal(normalizeKillSwitch('yes'), 'off');
  const h = harness({}, driverAction('wait', { reason: 'checks' }));
  const res = await drive(h, { killSwitch: undefined });
  assert.equal(res.skipped, 'kill-switch-off');
  assert.equal(h.seen.tick.length, 0);
});

test('dry-run: tick is told dryRun and no action is executed', async () => {
  const h = harness({}, driverAction('update-branch', { pr: 5 }));
  const res = await drive(h, { killSwitch: 'dry-run' });
  assert.equal(h.seen.tick[0].dryRun, true);
  assert.equal(h.seen.tick[0].actor, 'driver');
  assert.equal(res.executed, false);
  assert.deepEqual(h.bot.calls, []);
});

test('create-phase-branch uses the bot token at from_sha', async () => {
  const h = harness({}, driverAction('create-phase-branch', { phase: '1', branch: 'cursor/p-p1', from_sha: 'f'.repeat(40) }));
  await drive(h);
  assert.deepEqual(h.bot.calls, [['createRef', 'refs/heads/cursor/p-p1', 'f'.repeat(40)]]);
  assert.deepEqual(h.read.calls, []);
});

test('arm-auto-merge enables auto-merge with the pull node id', async () => {
  const h = harness({ pulls: { 5: { node_id: 'PR_5' } } }, driverAction('arm-auto-merge', { pr: 5, method: 'squash' }));
  await drive(h);
  assert.deepEqual(h.bot.calls, [['enableAutoMerge', 'PR_5', 'squash']]);
});

test('arm-auto-merge: clean status falls back to merging with the same method', async () => {
  const err = new GitHubError(200, 'POST /graphql failed: Pull request is in clean status');
  const h = harness({ pulls: { 5: { node_id: 'PR_5' } }, enableError: err }, driverAction('arm-auto-merge', { pr: 5, method: 'merge' }));
  await drive(h);
  assert.deepEqual(h.bot.calls.map((c) => c[0]), ['enableAutoMerge', 'mergePull']);
  assert.deepEqual(h.bot.calls[1], ['mergePull', 5, { method: 'merge' }]);
});

test('arm-auto-merge: other errors propagate', async () => {
  const h = harness({ pulls: { 5: { node_id: 'PR_5' } }, enableError: new GitHubError(200, 'boom') }, driverAction('arm-auto-merge', { pr: 5, method: 'squash' }));
  await assert.rejects(drive(h), /boom/);
});

test('merge action uses mergePull with the requested method', async () => {
  const h = harness({}, driverAction('merge', { pr: 5, method: 'squash' }));
  await drive(h);
  assert.deepEqual(h.bot.calls, [['mergePull', 5, { method: 'squash' }]]);
});

test('merge blocked records stop and needs-owner', async () => {
  const bot = fakeClient('bot', { pulls: { 5: { node_id: 'PR_5', head: { sha: 'f'.repeat(40) } } } });
  bot.mergePull = async () => { throw new GitHubError(405, 'Refusing to merge'); };
  const h = harness({}, driverAction('merge', { pr: 5, method: 'squash' }));
  h.clients.bot = bot;
  const res = await drive(h);
  assert.match(res.outcome, /merge blocked/);
  assert.deepEqual(bot.calls.filter((c) => c[0] === 'addLabels'), [['addLabels', 9, ['needs-owner']]]);
  assert.equal(bot.statusNow().stop.reason, 'merge-blocked');
});

const HEAD = 'd'.repeat(40);
const scopePull = { node_id: 'PR_5', head: { sha: HEAD, ref: 'cursor/p-p1', repo: { full_name: 'o/r' } }, base: { ref: 'cursor/p-integration-x' } };
const expected = (name) => new GitHubError(405, `PUT /repos/o/r/pulls/5/merge failed with 405: Repository rule violations found\n\nRequired status check "${name}" is expected.\n\n`);
const refusing = (h, err) => { h.bot.mergePull = async (...a) => { h.bot.calls.push(['mergePull', ...a]); throw err; }; };

test('republish-scope re-runs the check with the read token and records the head', async () => {
  const h = harness({ pulls: { 5: scopePull } }, driverAction('republish-scope', { pr: 5, head_sha: HEAD }));
  const res = await drive(h);
  assert.equal(h.seen.scopeRuns[0].client, 'read');
  assert.equal(h.seen.scopeRuns[0].headSha, HEAD);
  assert.equal(h.seen.scopeRuns[0].baseRef, 'cursor/p-integration-x');
  assert.deepEqual(h.seen.scope, [{ client: 'read', headSha: HEAD, conclusion: 'success', title: 'ok', summary: 'No violations.' }]);
  assert.deepEqual(h.bot.statusNow().dispatched.scope_republish, [{ sha: HEAD, at: NOW }]);
  assert.match(res.outcome, /republished execute-plan-scope on #5: success \(ok\)/);
});

test('republish-scope reports the published outcome when the STOP re-check turns it red', async () => {
  const stopped = { conclusion: 'failure', title: 'plan-stopped', summary: 'plan stopped: revoked', planId: PLAN_ID };
  const h = harness({ pulls: { 5: scopePull } }, driverAction('republish-scope', { pr: 5, head_sha: HEAD }), { scopeFinal: stopped });
  const res = await drive(h);
  assert.equal(h.seen.scope[0].title, 'plan-stopped');
  assert.match(res.outcome, /republished execute-plan-scope on #5: failure \(plan-stopped\)/);
});

test('republish-scope does nothing when the head moved', async () => {
  const h = harness({ pulls: { 5: scopePull } }, driverAction('republish-scope', { pr: 5, head_sha: 'e'.repeat(40) }));
  const res = await drive(h);
  assert.deepEqual(h.seen.scope, []);
  assert.match(res.outcome, /head moved/);
});

test('merge refused because execute-plan-scope is expected: republish once, no stop', async () => {
  const h = harness({ pulls: { 5: scopePull } }, driverAction('merge', { pr: 5, method: 'squash', head_sha: HEAD, scope_republished: false }));
  refusing(h, expected('execute-plan-scope'));
  const res = await drive(h);
  assert.match(res.outcome, /merge refused \(execute-plan-scope not counted\); republished/);
  assert.equal(h.seen.scope.length, 1);
  assert.equal(h.bot.statusNow().stop, null);
  assert.deepEqual(h.bot.calls.filter((c) => c[0] === 'addLabels'), []);
});

test('merge refused again after a republish, or for another check: STOP check-missing, enforced on the PR', async () => {
  const armed = { ...scopePull, auto_merge: { merge_method: 'squash' } };
  const again = harness({ pulls: { 5: armed } }, driverAction('merge', { pr: 5, method: 'squash', head_sha: HEAD, scope_republished: true }));
  refusing(again, expected('execute-plan-scope'));
  const res = await drive(again);
  assert.match(res.outcome, /check missing/);
  assert.equal(again.bot.statusNow().stop.reason, 'check-missing');
  assert.deepEqual(again.bot.calls.filter((c) => c[0] === 'addLabels'), [['addLabels', 9, ['needs-owner']]]);
  assert.deepEqual(again.bot.calls.filter((c) => c[0] === 'disableAutoMerge'), [['disableAutoMerge', 'PR_5']]);
  assert.deepEqual(again.seen.scope.map((s) => [s.client, s.headSha, s.conclusion, s.title]), [['read', HEAD, 'failure', 'plan-stopped']]);
  assert.equal(again.seen.scope[0].summary, 'plan stopped: check-missing');

  const ci = harness({ pulls: { 5: scopePull } }, driverAction('merge', { pr: 5, method: 'squash', head_sha: HEAD, scope_republished: false }));
  refusing(ci, new GitHubError(405, 'Repository rule violations found\n\nRequired status check "ci-gate / CI passed" was not set by the expected GitHub app.'));
  await drive(ci);
  assert.equal(ci.bot.statusNow().stop.reason, 'check-missing');
});

test('arm-auto-merge clean-status fallback gets the same recovery and stops instead of failing the pass', async () => {
  const clean = new GitHubError(200, 'POST /graphql failed: Pull request is in clean status');
  const h = harness({ pulls: { 5: scopePull }, enableError: clean }, driverAction('arm-auto-merge', { pr: 5, method: 'squash', head_sha: HEAD, scope_republished: false }));
  refusing(h, expected('execute-plan-scope'));
  assert.match((await drive(h)).outcome, /republished/);

  const other = harness({ pulls: { 5: scopePull }, enableError: clean }, driverAction('arm-auto-merge', { pr: 5, method: 'squash' }));
  refusing(other, new GitHubError(405, 'Pull Request is not mergeable'));
  assert.match((await drive(other)).outcome, /merge blocked/);
  assert.equal(other.bot.statusNow().stop.reason, 'merge-blocked');
  assert.deepEqual(other.seen.scope.map((s) => s.title), ['plan-stopped']);
});

test('driver log prints wait(reason)', async () => {
  const h = harness({}, driverAction('wait', { reason: 'checks' }));
  await drive(h);
  assert.match(h.log[0], /action driver:wait\(checks\)/);
});

test('update-branch uses the bot token', async () => {
  const h = harness({}, driverAction('update-branch', { pr: 8 }));
  await drive(h);
  assert.deepEqual(h.bot.calls, [['updateBranch', 8]]);
});

test('enforce-stop disables auto-merge and publishes plan-stopped on each head', async () => {
  const pulls = {
    3: { node_id: 'PR_3', auto_merge: { merge_method: 'squash' }, head: { sha: 's3' } },
    4: { node_id: 'PR_4', auto_merge: null, head: { sha: 's4' } },
  };
  const h = harness({ pulls }, { ...driverAction('enforce-stop', { prs: [3, 4] }), stop: { reason: 'revoked', detail: 'd' } });
  await drive(h);
  assert.deepEqual(h.bot.calls.filter((c) => c[0] === 'disableAutoMerge'), [['disableAutoMerge', 'PR_3']]);
  assert.deepEqual(h.seen.scope.map((s) => [s.client, s.headSha, s.conclusion, s.title]), [
    ['read', 's3', 'failure', 'plan-stopped'],
    ['read', 's4', 'failure', 'plan-stopped'],
  ]);
  assert.match(h.seen.scope[0].summary, /revoked/);
});

test('open-sync-pr opens once with the marker; an existing open PR is left alone', async () => {
  const args = { head: 'main', base: SNAP.integration_branch };
  const h = harness({}, driverAction('open-sync-pr', args));
  await drive(h);
  const [, pr] = h.bot.calls.find((c) => c[0] === 'createPull');
  assert.equal(pr.title, `execute-plan sync: main → ${SNAP.integration_branch}`);
  assert.equal(pr.head, 'main');
  assert.match(pr.body, new RegExp(`<!-- execute-plan-sync:${PLAN_ID} -->`));
  const again = harness({ openPulls: [{ number: 70 }] }, driverAction('open-sync-pr', args));
  await drive(again);
  assert.equal(again.bot.calls.filter((c) => c[0] === 'createPull').length, 0);
});

test('open-release-pr lists docs files, or N/A when there are none', async () => {
  const act = driverAction('open-release-pr', { head: SNAP.integration_branch, base: 'main' });
  const withDocs = harness({ compareFiles: ['docs/a.md', 'server/x.js'] }, act);
  await drive(withDocs);
  const [, pr] = withDocs.bot.calls.find((c) => c[0] === 'createPull');
  assert.equal(pr.title, `Release: ${SNAP.title} (${PLAN_ID})`);
  assert.equal(pr.base, 'main');
  assert.equal(pr.draft, false);
  assert.match(pr.body, new RegExp(`<!-- execute-plan-release:${PLAN_ID} -->`));
  assert.match(pr.body, /## Docs\n- `docs\/a\.md`/);
  assert.doesNotMatch(pr.body, /server\/x\.js/);
  assert.match(pr.body, /\| 1 \| First \|/);
  const noDocs = harness({ compareFiles: ['server/x.js'] }, act);
  await drive(noDocs);
  assert.match(noDocs.bot.calls.find((c) => c[0] === 'createPull')[1].body, /N\/A — no documentation files changed in this release/);
});

test('dispatch-preuat uses the read token and is recorded once per head', async () => {
  const sha = 'c'.repeat(40);
  const h = harness({}, driverAction('dispatch-preuat', { main_head_sha: sha }));
  await drive(h);
  assert.deepEqual(h.read.calls, [['dispatchWorkflow', 'pre-uat-e2e.yml', 'main']]);
  assert.deepEqual(h.bot.statusNow().dispatched.preuat_heads, [sha]);
  assert.match(h.bot.bodyNow(), /\| table \|/, 'the human table survives the rewrite');
  // the next pass sees the head recorded, so decide() would not ask again; recording appends, never replaces
  const again = harness({ status: baseStatus({ dispatched: { preuat_heads: ['old'], deploy_tags: [] } }) }, driverAction('dispatch-preuat', { main_head_sha: sha }));
  await drive(again);
  assert.deepEqual(again.bot.statusNow().dispatched.preuat_heads, ['old', sha]);
});

test('dispatch-deploy re-dispatches with deploy_ref and records the tag', async () => {
  const h = harness({}, driverAction('dispatch-deploy', { tag: 'uat-261014-1892' }));
  await drive(h);
  assert.deepEqual(h.read.calls, [['dispatchWorkflow', 'deploy-uat.yml', 'main', { deploy_ref: 'uat-261014-1892' }]]);
  assert.deepEqual(h.bot.statusNow().dispatched.deploy_tags, ['uat-261014-1892']);
});

test('launch: starts the worker on the action branch, records launch and lease', async () => {
  const args = { phase: '1', branch: 'cursor/p-p1', base: SNAP.integration_branch, pr: null };
  const h = harness({}, agentAction('implement', args, { phase: '1' }));
  await drive(h);
  const [launch] = h.seen.launch;
  assert.equal(launch.startingRef, 'cursor/p-p1');
  assert.equal(launch.model, 'model-impl');
  assert.equal(launch.apiKey, 'key');
  assert.equal(launch.repoUrl, 'https://github.com/o/r');
  assert.match(launch.prompt, /^\/execute-plan proof-build-label-7f3a/);
  const status = h.bot.statusNow();
  assert.deepEqual(status.launches, [{ at: NOW, phase: '1', kind: 'implement', agent_id: 'bc-1', run_id: 'run-1' }]);
  assert.deepEqual(status.lease, { platform: 'cursor', agent_id: 'bc-1', run_id: 'run-1', launched_at: NOW, last_tick_at: NOW });
});

test('launch: the worker gets the bot token in envVars, and the token is never logged', async () => {
  const h = harness({}, agentAction('implement', { phase: '1', branch: 'b', base: 'i' }, { phase: '1' }));
  await drive(h);
  assert.deepEqual(h.seen.launch[0].envVars, {
    GH_TOKEN: 'bot-secret-token',
    EXECUTE_PLAN_TOKEN: 'bot-secret-token',
    OWNER_GH_TOKEN: '',
    BOT_GH_TOKEN: '',
  });
  assert.ok(!h.log.join('\n').includes('bot-secret-token'));
  assert.ok(!h.seen.launch[0].prompt.includes('bot-secret-token'));
});

test('launch: no bot token → refuses to launch', async () => {
  const h = harness({}, agentAction('implement', { phase: '1', branch: 'b', base: 'i' }, { phase: '1' }), { noBotToken: true });
  await assert.rejects(drive(h), /EXECUTE_PLAN_BOT_TOKEN/);
  assert.equal(h.seen.launch.length, 0);
});

test('dry-run never launches, even with a bot token', async () => {
  const h = harness({}, agentAction('implement', { phase: '1', branch: 'b', base: 'i' }, { phase: '1' }));
  await drive(h, { killSwitch: 'dry-run' });
  assert.equal(h.seen.launch.length, 0);
});

test('launch: fix actions use the fix model; release-level work counts under "release"', async () => {
  const h = harness({ pulls: { 6: { base: { ref: 'main' } } } }, agentAction('fix-ci', { pr: 6, branch: 'b', failing: ['ci'] }, { phase: null }));
  await drive(h);
  assert.equal(h.seen.launch[0].model, 'model-fix');
  assert.match(h.seen.launch[0].prompt, /Base: main/);
  assert.equal(h.bot.statusNow().launches[0].phase, 'release');
});

test('launch: resolve-sync creates its branch off the integration head first', async () => {
  const branch = `cursor/${PLAN_ID}-sync-1`;
  const h = harness({}, agentAction('resolve-sync', { sync_pr: 12, branch }, { phase: null }));
  h.bot.getPull = async () => ({ base: { ref: SNAP.integration_branch } });
  await drive(h);
  assert.deepEqual(h.bot.calls.find((c) => c[0] === 'createRef'), ['createRef', `refs/heads/${branch}`, `sha-of-${SNAP.integration_branch}`]);
});

test('launch: keeps only the last 50 launches', async () => {
  const many = Array.from({ length: 50 }, (_, i) => ({ at: `2026-10-15T00:00:${String(i).padStart(2, '0')}Z`, phase: '1', kind: 'implement', agent_id: `a${i}`, run_id: 'r' }));
  const h = harness({ status: baseStatus({ launches: many }) }, agentAction('implement', { phase: '1', branch: 'b', base: 'i' }, { phase: '1' }));
  await drive(h);
  const { launches } = h.bot.statusNow();
  assert.equal(launches.length, 50);
  assert.equal(launches[49].agent_id, 'bc-1');
  assert.equal(launches[0].agent_id, 'a1');
});

test('launch without a Cursor key fails loudly', async () => {
  const h = harness({}, agentAction('implement', { phase: '1', branch: 'b', base: 'i' }, { phase: '1' }), { noKey: true });
  await assert.rejects(drive(h), /cursor_api_key/);
});

test('lease alive: the lease with its Cursor status goes to tick and nothing is launched', async () => {
  const lease = { platform: 'cursor', agent_id: 'bc-9', run_id: 'run-9', launched_at: '2026-10-16T09:50:00Z', last_tick_at: '2026-10-16T09:55:00Z' };
  const h = harness({ status: baseStatus({ lease }) }, driverAction('wait', { reason: 'agent-alive' }));
  const res = await drive(h);
  assert.deepEqual(h.seen.leaseQueries, [{ apiKey: 'key', agentId: 'bc-9', runId: 'run-9' }]);
  assert.deepEqual(h.seen.tick[0].lease, { ...lease, status: 'RUNNING' });
  assert.equal(h.seen.launch.length, 0);
  assert.equal(res.executed, false);
});

test('no lease → tick gets lease null; without a Cursor key the lease status is UNKNOWN', async () => {
  const none = harness({}, driverAction('wait', { reason: 'checks' }));
  await drive(none);
  assert.equal(none.seen.tick[0].lease, null);
  const lease = { platform: 'cursor', agent_id: 'bc-9', run_id: 'run-9', launched_at: NOW, last_tick_at: NOW };
  const keyless = harness({ status: baseStatus({ lease }) }, driverAction('wait', { reason: 'agent-alive' }), { noKey: true });
  await drive(keyless);
  assert.equal(keyless.seen.tick[0].lease.status, 'UNKNOWN');
  assert.equal(keyless.seen.leaseQueries.length, 0);
});

test('agent action without launch (worker is alive elsewhere) launches nothing', async () => {
  const h = harness({}, { action: { actor: 'agent', kind: 'fix-ci', launch: false, args: { pr: 1, branch: 'b', failing: [] } } });
  await drive(h);
  assert.equal(h.seen.launch.length, 0);
});

test('buildHandoffPrompt follows contracts §3.6', () => {
  const decision = { phase: '1', action: { actor: 'agent', kind: 'triage-review', launch: true, args: { pr: 4, branch: 'cursor/p-p1', threads: ['https://x/1', 'https://x/2'] } } };
  const text = buildHandoffPrompt(decision, SNAP, PLAN_MD, { base: SNAP.integration_branch });
  assert.match(text, /Action: triage-review — /);
  assert.match(text, /Branch: cursor\/p-p1 {3}Base: cursor\/proof-build-label-7f3a-integration-7f3a {3}PR: #4 {3}Phase: 1 "First"/);
  assert.match(text, /Scope \(allowed\): a\/\*\* {3}Companions: b\.md/);
  assert.match(text, /Evidence: https:\/\/x\/1, https:\/\/x\/2/);
  assert.match(text, /tick proof-build-label-7f3a --json --actor agent/);
  assert.match(text, /Run\n\.\/scripts\/pre-push-changed\.sh before every push and push only when it is green/);
  assert.match(text, /worker done: blocked <check>: <reason>/);
});

test('plansForEvent per event type; fork PRs are ignored', async () => {
  const active = [{ planId: 'plan-aaa', issueNumber: 1 }, { planId: 'plan-bbb', issueNumber: 2 }];
  const client = {
    listIssues: async ({ labels }) => (labels.includes('autonomous-approved')
      ? active.map((p) => ({ number: p.issueNumber, labels: [{ name: 'execute-plan' }, { name: 'autonomous-approved' }, { name: `plan:${p.planId}` }] }))
      : [{ number: 2, labels: [] }]),
  };
  const run = (eventName, payload, inputPlanId = '') => plansForEvent({ eventName, payload, inputPlanId, repo: 'o/r', client });
  const prEvent = (head, base, repo = 'o/r') => ({ pull_request: { head: { ref: head, repo: { full_name: repo } }, base: { ref: base } } });

  assert.deepEqual(await run('pull_request', prEvent('cursor/plan-aaa-p1', 'cursor/plan-aaa-integration-1234')), [active[0]]);
  assert.deepEqual(
    await run('pull_request_target', prEvent('cursor/plan-aaa-p1', 'cursor/plan-aaa-integration-1234')),
    [active[0]],
  );
  assert.deepEqual(await run('pull_request_review', prEvent('cursor/plan-bbb-sync-1', 'cursor/plan-bbb-integration-1234')), [active[1]]);
  assert.deepEqual(await run('pull_request_target', prEvent('cursor/plan-aaa-p1', 'x', 'fork/r')), []);
  assert.deepEqual(await run('pull_request', prEvent('feature/x', 'main')), []);
  const ci = (prs) => ({ workflow_run: { name: 'CI', pull_requests: prs } });
  assert.deepEqual(await run('workflow_run', ci([{ head: { ref: 'cursor/plan-bbb-p2' }, base: { ref: 'cursor/plan-bbb-integration-1234' } }])), [active[1]]);
  assert.deepEqual(await run('workflow_run', ci([])), active);
  assert.deepEqual(await run('workflow_run', { workflow_run: { name: 'Pre-UAT E2E', pull_requests: [] } }), active);
  assert.deepEqual(await run('schedule', {}), active);
  assert.deepEqual(await run('workflow_dispatch', {}), active);
  assert.deepEqual(await run('workflow_dispatch', {}, 'plan-bbb'), [{ planId: 'plan-bbb', issueNumber: 2 }]);
  assert.deepEqual(await run('issues', { issue: { labels: [{ name: 'plan:plan-aaa' }, { name: 'needs-owner' }] } }), [active[0]]);
  assert.deepEqual(await run('issues', { issue: { labels: [{ name: 'bug' }] } }), []);
});
