---
title: Execute-plan v2 — runtime work packages (WP1–WP5)
owner: Kanopee
audience: agent
status: active
last_updated: 2026-10-15
tags: [agent, execute-plan, autonomy]
---
# Execute-plan v2 — runtime work packages (WP1–WP5)

Part of [execute-plan-v2.md](../execute-plan-v2.md). Contracts: [contracts.md](./contracts.md).
Common to every WP: branch from `main`; one PR; `./scripts/pre-push-changed.sh` green before push;
new test files added to the `node --test` line at `scripts/pre-push-changed.sh:135`; PR body with
`## Docs`; no file over 500 lines; no `gh` in new code; tests offline on fixtures; v1 behaviour
unchanged (`schema_version` absent/`1` → existing code paths). CLI entry point stays
`scripts/execute_plan_runtime.js`; new subcommands are registered there and delegate to modules.

## WP1 — GitHub client and fixtures

**Branch:** `claude/execute-plan-v2-wp1` · **Size:** ~350 lines code, ~250 lines tests/fixtures

**Files**
- `scripts/lib/execute_plan_github.js` (new) — REST + GraphQL client over global `fetch`.
- `scripts/test/fixtures/execute-plan-v2/README.md` — fixture format.
- `scripts/test/fixtures/execute-plan-v2/replay-1894-1895/*.json` — recorded responses (see below).
- `scripts/test/execute_plan_github.test.js` (new).

**Exports**
```js
/** @typedef {{ method?: string, path: string, query?: Record<string,string|number>, body?: any, graphql?: string, variables?: any }} GhRequest */
/** @param {{ token?: string, repo: string, fetchImpl?: typeof fetch, baseUrl?: string }} opts */
function createGitHubClient(opts)  // → client
// client methods (all async, all paginate where GitHub paginates):
client.getRepo(); client.getIssue(n); client.listIssueComments(n); client.createComment(n, body);
client.updateComment(id, body); client.addLabels(n, labels); client.removeLabel(n, label);
client.listPulls({ head, base, state }); client.getPull(n); client.listPullFiles(n)  // throws PullFilesOverflow when > 3000
client.listCheckRuns(sha); client.compare(base, head)  // → { status, ahead_by, behind_by, files: [{filename,status}] }
client.listWorkflowRuns(file, { branch, event, per_page }); client.getWorkflowRun(id); client.listRunJobs(id);
client.dispatchWorkflow(file, ref, inputs); client.rerunFailedJobs(id);
client.listTags(); client.getBranch(name); client.createRef(ref, sha); client.createPull({ title, head, base, body, draft });
client.mergePull(n, { method }); client.updateBranch(n); client.enableAutoMerge(nodeId, method); client.disableAutoMerge(nodeId);
client.listUnresolvedThreads(n)  // GraphQL → [{ url, path, line, author }]
client.getFileAtRef(path, ref)   // → { content: string, sha }
/** Replays recorded responses; throws on an unrecorded request. */
function createFixtureClient(fixtureDir)
/** Records live responses into fixtureDir (manual use only; never in tests). */
function createRecordingClient(opts, fixtureDir)
```

**Rules**
1. Token resolution: `EXECUTE_PLAN_TOKEN` → `GH_TOKEN` → `GITHUB_TOKEN`; missing token → throw `MissingToken` at first call, not at construction.
2. Every request sends `Accept: application/vnd.github+json`, `X-GitHub-Api-Version: 2022-11-28`, `User-Agent: execute-plan/2`.
3. Retries: `502/503/504` and `secondary rate limit` → 3 attempts, exponential 2 s/4 s/8 s. `403` with `x-ratelimit-remaining: 0` → throw `RateLimited` with reset time; never spin.
4. Fixture format: one JSON file per request, name `<METHOD>_<path with / → _>_<sha1(query+body)[0:8]>.json`, content `{ request, status, headers, body }`. The fixture client matches on method, path, query and body.
5. Replay fixture: record issue `#1894` (comments, labels, timeline), PR `#1895` (pull, files, check runs on head `e80264e`), the integration-branch snapshot and the head-branch snapshot. Owner runs the recorder once (`node scripts/execute_plan_runtime.js record-fixtures --plan care-date-blocks-v4-e8f1 --issue 1894 --pr 1895 --out scripts/test/fixtures/execute-plan-v2/replay-1894-1895`); strip tokens and emails from recorded bodies.

**Tests:** `pagination follows Link headers`, `listPullFiles overflow throws`, `retry on 502 then success`, `rate limit throws RateLimited`, `token resolution order`, `fixture client throws on unrecorded request`, `compare maps status and files`, `unresolved threads GraphQL mapping`.

**Acceptance:** `node --test scripts/test/execute_plan_github.test.js && ./scripts/pre-push-changed.sh`

**Docs:** add a row to `docs/agent-efficiency/README.md` tooling table pointing at the client; note in `docs/engineering/cursor-agent-framework.md` § tooling that new GitHub I/O uses it.

**Kickoff prompt:** "Implement WP1 of docs/agent-efficiency/plans/execute-plan-v2.md (read the index, contracts.md, and the WP1 section of work-packages-runtime.md). Branch from main. Offline tests only. Open a draft PR, mark ready when pre-push-changed is green."

## WP2 — Scope matcher and `check-diff`

**Branch:** `claude/execute-plan-v2-wp2` · **Size:** ~300 lines code, ~250 lines tests

**Files**
- `scripts/lib/execute_plan_scope.js` (new) — protected set, categories, classification.
- `scripts/execute_plan_runtime.js` — register `check-diff`.
- `scripts/test/execute_plan_scope.test.js` (new).
- Leave `classifyFile`/`classifyWithException` in `execute_plan_schema.js:84-105` untouched for v1.

**Exports**
```js
const PROTECTED_PATHS_V1 = [ 'scripts/execute_plan_runtime.js', 'scripts/lib/execute_plan_*', 'scripts/execute_plan_*.test.js',
  '.github/**', '.cursor/rules/**', '.cursor/skills/**', '.cursor/hooks.json', '.claude/**', 'AGENTS.md', 'CLAUDE.md' ];
// plus FORBIDDEN_PATH_PATTERNS imported from .github/scripts/agent-safety-lib.js (import, never copy)
/** @returns {'phase'|'sync'|'sync-resolve'|'release'|'remedial'|'init'|null} */
function categorizePull(pr, snapshot)   // by head/base refs: phase branch→integration; main→integration; cursor/<id>-sync-N→integration; integration→main; cursor/<id>-remedial-N→main; cursor/<id>-init→(none, init branch has no PR)
/** @returns {{ ok: boolean, reason: string, category: 'protected'|'forbidden'|'allowed'|'companion'|'exception:tests'|'exception:docs'|'drift'|'unclassified' }} */
function classifyPath(file, { snapshot, phase, prCategory })
/** @returns {{ ok, verdict: 'green'|'red', violations: [{file, reason}], companionsUsed: string[], evidence }} */
function evaluateDiff(files, { snapshot, phase, prCategory, controlState })
```

**Rules (evaluation order per file — forbidden first, B5/R9)**
1. `.agents/plans/<plan_id>.md` or `.snapshot.json` changed → `drift` → red.
2. Protected set or `FORBIDDEN_PATH_PATTERNS` match → `protected`/`forbidden` → red, regardless of `allowed_paths`.
3. Plan `forbidden_paths` match → red.
4. Category scope: `phase` → the phase's `allowed_paths`; `release` and `sync-resolve` → union of all phases' `allowed_paths` (files are `compare(main...head).files`); `remedial` → that union ∪ `e2e/**` ∪ test category; `sync` (head is `main`) → always green with no file evaluation.
5. Exceptions are real categories: `tests` ⇔ `**/test/**`, `**/*.test.{js,mjs,ts}`, `**/*_test.dart`, `e2e/**/*.spec.ts`; `docs` ⇔ `docs/**`, `**/*.md` outside `.agents/` and `.cursor/`. Only if the phase lists the exception.
6. Companions: phase `companions` globs plus the fixed generated/barrel list `['**/generated/**', '**/*.g.dart', '**/*.freezed.dart', 'flutter_app/lib/l10n/*.arb', 'openapi/*.json', '**/index.{js,ts,dart}']`; ≤ 5 companion files per PR, each reported in `companionsUsed`.
7. Anything else → `unclassified` → red.
8. `controlState` (from the status comment / labels): `stop`, revoked, expired or invalid approval → red with reason `plan-stopped` even when files are fine (B3).

**CLI:** `node scripts/execute_plan_runtime.js check-diff <plan_id> --pr <n> [--json]` — v2 only; uses the client from WP1; exit `0` green, `1` red, `3` config error. It is the function the scope workflow calls (WP8).

**Tests:** `forbidden beats allowed overlap (server/** vs server/auth/**)`, `exception tests only matches test files`, `exception docs rejects care_item.dart`, `companion openapi green and reported`, `sixth companion red`, `snapshot edit is drift`, `workflow edit is protected`, `release union`, `remedial allows e2e`, `sync head main green`, `stopped plan red`, `unclassified red`. Fixture: phase 1 of the replay snapshot with `care_item/care_item.dart` → red `unclassified` (the real drift from 2026-10-14).

**Acceptance:** `node --test scripts/test/execute_plan_scope.test.js && ./scripts/pre-push-changed.sh`

**Docs:** `docs/agent-efficiency/execute-plan-schema.md` (or the file documenting the snapshot — **VERIFY:** `rg -l "allowed_exceptions" docs | head`) § Scope: evaluation order, categories, companions.

**Kickoff prompt:** "Implement WP2 of docs/agent-efficiency/plans/execute-plan-v2.md (index, contracts.md §3.1, work-packages-runtime.md WP2). Forbidden-first matcher, categories, check-diff CLI. Offline tests. Draft PR, ready when green."

## WP3 — Snapshot v2, `init`, approval hash

**Branch:** `claude/execute-plan-v2-wp3` · **Size:** ~400 lines code, ~250 lines tests

**Files**
- `scripts/lib/execute_plan_approval.js` (new) — `canonical`, `computeApprovalHash`, `APPROVAL_RE`, `parseApprovalComment`, `validateApproval`.
- `scripts/lib/execute_plan_snapshot_v2.js` (new) — `validateSnapshotV2`, `loadSnapshotAtRef`, `buildSnapshotFromPlan`.
- `scripts/lib/execute_plan_constants.js` — add `V2_CAPS = { window_days: 14, ci_per_phase: 3, launches_per_phase: 3, remedial_rounds: 3, sync_attempts: 2, daily_launches: 10 }` and `V2_DEFAULT_WINDOW_DAYS = 7`.
- `scripts/validate_execute_plan_snapshot.js` — route `schema_version: 2` to the v2 validator; `--fix-hash` refuses v2 files.
- `scripts/execute_plan_runtime.js` — register `init`.
- `.agents/plans/_example.v2.snapshot.json` + `_example.v2.md` — the §3.1 object and a matching plan file; add both to the pre-push validation lines next to `_example.snapshot.json`.
- `scripts/test/execute_plan_approval.test.js`, `scripts/test/execute_plan_snapshot_v2.test.js` (new).

**Exports**
```js
function canonical(value)                                    // contracts §3.4
function computeApprovalHash(snapshot)                       // → 'sha256:…', ignores snapshot.approval_hash
const APPROVAL_RE                                             // contracts §3.3
function parseApprovalComment(body)                          // → { plan, hash, until } | null
/** @param {{ comment, snapshot, config: { owners: string[], bot_login: string }, now: Date }} */
function validateApproval(args)                              // → { ok, reason? }  reasons: not-owner|bot|edited|plan|hash|until|window
function validateSnapshotV2(snapshot, { planFileBytes })     // throws ExecutePlanError; checks every rule in contracts §3.1 incl. caps and plan_file_sha256
async function loadSnapshotAtRef(client, planId, ref)        // reads .agents/plans/<id>.snapshot.json and <id>.md at ref; verifies hash; → { snapshot, planMarkdown }
function buildSnapshotFromPlan({ planMarkdown, planId, controlIssue, now, settings })  // phases parsed from "### Phase <id> — <title>" sections with a fenced ```yaml scope block (allowed_paths, forbidden_paths, allowed_exceptions, companions, exit_checklist)
```

**`init` command:** `node scripts/execute_plan_runtime.js init <plan_id> [--window-days 7] [--dry-run]`
1. Requires `.agents/plans/<plan_id>.md` on the current branch, named `cursor/<plan_id>-init` (or `claude/<plan_id>-init`); refuses on any other branch and refuses if the working tree has changes outside `.agents/plans/<plan_id>.*`.
2. Validates the plan file headings (contracts §3.2; rejects `## Contract`/`## Rules`).
3. Creates the control issue (title `execute-plan: <title> (<plan_id>)`, label `execute-plan`) with a body listing phases, paths, window, and `Approval hash: pending`.
4. Builds the snapshot with the issue number, computes `approval_hash`, writes the snapshot, commits both files (`execute-plan init <plan_id>`), pushes the init branch.
5. Edits the issue body: hash, init branch head SHA, and the exact approval line the owner must paste: `approve-autonomous <plan_id> sha256:<hash> until <approved_until>`.
6. Prints that line and **stops**. The agent's turn ends here by design; `init` is the one human checkpoint.

**Tests:** vectors from contracts §3.4 (`canonical empty`, `canonical sorted`, `approval hash example`), `hash ignores approval_hash field`, `hash changes when plan md changes`, `approval regex accepts exact / rejects trailing text`, `validateApproval: not-owner, bot, edited, wrong hash, wrong until, window over cap`, `snapshot caps: raising a budget rejected, lowering accepted`, `integration branch pattern`, `phase branch pattern`, `v1 file routed unchanged`, `--fix-hash refuses v2`, `init dry-run output`.

**Acceptance:** `node --test scripts/test/execute_plan_approval.test.js scripts/test/execute_plan_snapshot_v2.test.js && node scripts/validate_execute_plan_snapshot.js .agents/plans/_example.v2.snapshot.json && ./scripts/pre-push-changed.sh`

**Docs:** `docs/agent-efficiency/plan-template.md` — add the v2 plan layout (headings + yaml scope block); `docs/agent-efficiency/autonomous-pr-policy.md:313` — replace "new snapshot + approve-autonomous again" with "plan changes after approval are impossible; start a new plan".

**Kickoff prompt:** "Implement WP3 of docs/agent-efficiency/plans/execute-plan-v2.md (index, contracts.md §3.1–3.4, work-packages-runtime.md WP3). Approval hash with the given vectors, snapshot v2 validator, init command. v1 untouched. Offline tests. Draft PR, ready when green."

## WP4 — `tick`: phases, sync, release

**Branch:** `claude/execute-plan-v2-wp4` · **Size:** ~450 lines code (two modules), ~350 lines tests

**Files**
- `scripts/lib/execute_plan_state.js` (new) — pure derivation from observations to a state (contracts §4, phases/sync/release rows).
- `scripts/lib/execute_plan_tick.js` (new) — observation gathering, action selection, lease and status comment, log comments.
- `scripts/lib/execute_plan_control.js` (new, small) — control issue reads: approval comment, labels, status comment parse/format, config file from `main`.
- `scripts/execute_plan_runtime.js` — register `tick` and `watch-ci`.
- `scripts/test/execute_plan_state.test.js`, `scripts/test/execute_plan_tick.test.js` (new).

**Exports**
```js
/** Pure. @param {Observations} obs @returns {{ state, phase?, prs, budgets, evidence }} */
function deriveState(snapshot, obs)
/** Pure. @returns {{ action, stop }} per contracts §3.7 */
function selectAction(snapshot, derived, { now, lease, config })
/** Gathers observations through the client; no decisions. */
async function observe(client, snapshot, { now })
/** One tick: observe → derive → select → persist (status comment, lease, log comment) → return output. */
async function tick(client, { planId, now, actor: 'driver'|'agent', agentId?, dryRun })
async function watchCi(client, { pr, timeoutMin = 25, pollSec = 60 })   // → { conclusion, failing: [...] }
```

**Rules**
1. `tick` reads the snapshot and plan file **from the integration branch** via `loadSnapshotAtRef` (never the checked-out copy), and the config from `main`.
2. Order of evaluation: stopped? → complete? (delegated to WP5 when a release merge exists) → release → sync → phases. The first matching row wins.
3. Phase PR = most recent PR with `head = phase.branch`, `base = integration_branch`. Phase merged ⇔ `merged_at` set.
4. CI attempts per PR = count of check runs named `ci-gate / CI passed` with `conclusion = failure` across the PR's commits (`GET /pulls/{n}/commits` then check runs per sha); ≥ budget → STOP `ci-budget`.
5. `rerun-ci` is allowed once per head SHA and only when the failed job has no test step output (`listRunJobs` step name does not start with `Test`/`Run`); otherwise the failure counts and `fix-ci` is selected.
6. `arm-auto-merge` only when: PR ready, no unresolved threads, at least one required check still pending or all green, and for `main`-based PRs either a Copilot review was submitted or 15 min passed since ready. If GitHub answers "clean status" → `merge-now`.
7. Lease: `actor: 'agent'` ticks refresh `lease.last_tick_at`; `actor: 'driver'` ticks never create a lease. `selectAction` returns an `agent` action with `launch: true` only when the lease is dead (contracts §3.5) and budgets allow; otherwise `wait` with `reason: 'agent-alive'`.
8. Launch budgets: `launches[phase] < launches_per_phase` and `launches_today < daily_launches`; the launch itself is recorded by the driver (WP7) through `recordLaunch(client, planId, { phase, agentId })` exported here.
9. Sync: before `open-release-pr`, if `compare(main...integration).behind_by > 0` → `open-sync-pr` (title `execute-plan sync: main → <integration>`, body marker `<!-- execute-plan-sync:<id> -->`), method `merge`. Not mergeable (`mergeable_state = dirty`) → `resolve-sync` on `cursor/<id>-sync-<n>` (n = sync attempts + 1); the resolve PR targets integration and is category `sync-resolve`. Attempts ≥ budget → STOP `sync-conflict`.
10. `open-release-pr`: title `Release: <plan title> (<plan_id>)`, body with the phase table, `## Docs` section, and marker `<!-- execute-plan-release:<id> -->`; draft = false; if `release_owner_review` → do not arm auto-merge; state stays `release:open` with `wait: owner-review` (not a STOP).
11. `update-branch` when `mergeable_state = behind` on a `strict` base; counts nothing.
12. Status comment and log comment per contracts §3.5; `--dry-run` prints what it would write.
13. `watch-ci` polls check runs for the PR head; returns on completion or timeout; never ends the process with a non-zero code on timeout (exit `0`, `timedOut: true`) so the worker runs `tick` next.

**CLI:** `node scripts/execute_plan_runtime.js tick <plan_id> [--json] [--actor agent|driver] [--agent-id …] [--dry-run]`; `watch-ci <plan_id> --pr <n> [--timeout-min 25]`.

**Tests (fixture-driven, names from contracts §4.3 for phase/sync/release rows)** plus: `tick reads snapshot from integration not checkout`, `lease alive → wait agent-alive`, `lease stale → launch`, `daily cap → STOP launch-budget`, `rerun once per head`, `copilot wait 15 min on main PRs`, `owner-review → wait not stop`, `replay-1894-1895 → state phase:ready, action arm-auto-merge` (where the agent stopped on 2026-10-14).

**Acceptance:** `node --test scripts/test/execute_plan_state.test.js scripts/test/execute_plan_tick.test.js && ./scripts/pre-push-changed.sh`

**Docs:** `docs/agent-efficiency/execute-plan-instruction-stack.md` — add § v2 loop (tick/watch-ci) above the platform table; the table itself is deleted in WP10.

**Kickoff prompt:** "Implement WP4 of docs/agent-efficiency/plans/execute-plan-v2.md (index, contracts.md §3.5–4.3, work-packages-runtime.md WP4). Pure deriveState/selectAction + tick + watch-ci. Offline fixtures incl. replay-1894-1895. Draft PR, ready when green."

## WP5 — `tick`: UAT stage, watchers, `complete-plan` verification

**Branch:** `claude/execute-plan-v2-wp5` · **Size:** ~400 lines code, ~300 lines tests

**Files**
- `scripts/lib/execute_plan_uat.js` (new) — UAT observations and derivation (contracts §4 rows from `release:merged` to `complete`, §4.2 classes).
- `scripts/lib/execute_plan_state.js` — call into `execute_plan_uat.js` when a release merge exists.
- `scripts/execute_plan_runtime.js` — register `watch-preuat`, `watch-deploy`; `complete-plan` for v2 verifies instead of writing.
- `scripts/test/execute_plan_uat.test.js` (new) + fixtures recorded from real runs: one green Pre-UAT, one red (shard list), one cancelled, one throttle-skipped Promote (`::notice::Skipping tag` in logs → use run conclusion `success` with no tag), one red Deploy UAT.

**Exports**
```js
async function observeUat(client, { mergeSha, mergedAt })   // runs of pre-uat-e2e.yml / promote-uat.yml / deploy-uat.yml / uat-live-e2e.yml, tags, compare results
/** Pure. */ function deriveUatState(snapshot, uatObs, { now })  // → awaiting-preuat | remedial | awaiting-main-green | awaiting-promote | awaiting-deploy | complete | stop
/** Pure. */ function failingShards(run, jobs)                 // → sorted job names with conclusion failure, excluding gate-summary
/** Pure. */ function classifyDeployFailure(run, jobs)        // → 'infra-transient' | 'infra-migration' | 'app-smoke' | 'unknown'
async function watchPreUat(client, { mergeSha, timeoutMin = 90 })
async function watchDeploy(client, { mergeSha, timeoutMin = 45 })
async function verifyComplete(client, snapshot)               // → { complete: boolean, evidence: { release_pr, merge_sha, preuat_run, tag, deploy_run, tier3 } }
```

**Rules**
1. "Contains" is always `compare(merge_sha...candidate).status ∈ {ahead, identical}` (B2). Never match by exact SHA or prefix.
2. Pre-UAT candidate runs: `listWorkflowRuns('pre-uat-e2e.yml', { branch: 'main' })` with `created_at ≥ mergedAt`, `event ∈ {push, workflow_dispatch}`; ignore `conclusion ∈ {cancelled, skipped}`.
3. Baseline run = latest completed non-cancelled Pre-UAT run whose head is an ancestor of `merge_sha` and ≠ `merge_sha`. App-caused ⇔ `failingShards(candidate) ⊄ failingShards(baseline)` or baseline is green. Baseline red with the same shards → `awaiting-main-green`; > 6 h → STOP `main-red`.
4. `dispatch-preuat` only when no Pre-UAT run for `main` HEAD is queued/in progress and (merge ≥ 10 min ago or the throttle skipped); at most once per `main` HEAD.
5. Tag check: `listTags()` entries matching `^uat-` whose `commit.sha` contains `merge_sha`.
6. Deploy run: `listWorkflowRuns('deploy-uat.yml')` with `created_at ≥ mergedAt` and head containing `merge_sha`; `success` → complete; `failure` → `classifyDeployFailure` → §4.2; the re-dispatch uses `dispatchWorkflow('deploy-uat.yml', 'main', { deploy_ref: tag })` once.
7. Tier 3: latest `uat-live-e2e.yml` run after the deploy; recorded in `uat.tier3`; blocks completion only if `settings.tier3_blocking`.
8. `remedial` action args: failing shards, baseline run url, branch `cursor/<id>-remedial-<n>`; the remedial PR targets `main` and follows the `release:open` rules; after its merge, `merge_sha` becomes the remedial merge SHA and the stage restarts at `awaiting-preuat`.
9. `complete-plan <plan_id>` (v2): runs `verifyComplete`; if complete → final status comment, log comment with the four evidence links, label `plan:complete`, close the issue; else exit `2` with the missing condition. It never sets a flag by itself.

**Tests:** contracts §4.3 UAT rows plus `contains via compare not prefix`, `cancelled ignored`, `baseline selection skips merge_sha itself`, `dispatch once per HEAD`, `tier3 advisory recorded`, `tier3 blocking waits`, `complete-plan refuses without deploy`, `remedial restarts stage with new merge_sha`.

**Acceptance:** `node --test scripts/test/execute_plan_uat.test.js && node --test scripts/test/execute_plan_state.test.js && ./scripts/pre-push-changed.sh`

**Docs:** `docs/e2e/uat-deploy-tiers.md` § "Execute-plan v2 observes this chain" (what is read, what is dispatched, never more than one dispatch per HEAD); `.cursor/skills/babysit-uat/SKILL.md` line 8 note: v2 plans are driven by `tick` (full rewrite in WP6).

**Kickoff prompt:** "Implement WP5 of docs/agent-efficiency/plans/execute-plan-v2.md (index, contracts.md §4–4.3, work-packages-runtime.md WP5). UAT stage derivation with ancestry via compare, failure classes, watchers, complete-plan verification. Offline fixtures from real runs. Draft PR, ready when green."
