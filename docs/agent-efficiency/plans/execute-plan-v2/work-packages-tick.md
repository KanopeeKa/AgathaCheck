---
title: Execute-plan v2 — runtime work packages WP4a–WP5 (decide, tick, UAT)
owner: Kanopee
audience: agent
status: active
last_updated: 2026-10-15
tags: [agent, execute-plan, autonomy]
---
# Execute-plan v2 — runtime work packages WP4a–WP5

Part of [execute-plan-v2.md](../execute-plan-v2.md). Contracts: [contracts.md](./contracts.md).
State machine (normative for these WPs): [state-machine.md](./state-machine.md).
The "Rules for every runtime WP" at the top of [work-packages-runtime.md](./work-packages-runtime.md) apply.

## WP4a — Pure decision logic for control, phases, sync, release

**Depends on:** WP2, WP3 · **Recommended executor:** Claude Code · **Size:** ~350 code, ~200 test code + scenario JSON

**Files**
- Create: `scripts/lib/execute_plan_control.js`, `scripts/lib/execute_plan_state.js`,
  `scripts/test/execute_plan_scenarios.test.js`, `scripts/test/helpers/execute_plan_scenarios.js`,
  `scripts/test/fixtures/execute-plan-v2/scenarios/_base.snapshot.json`,
  `…/_base.observations.json`, `…/_base.pr.json`, `…/_base.uat.json`, and one JSON file per
  P/L/S/R/D scenario in state-machine §4.5 (32 files).

**Do not touch:** WP1–WP3 modules except importing them; no I/O in these two modules (no
`fetch`, no `fs`, no `process.env`, no `Date.now()` — time comes from `opts.now`).

**Exports**
```js
// execute_plan_control.js
const RUNNING_SET = new Set(['CREATING', 'RUNNING']);
/** @returns {{ epoch: string|null, deadline: string|null, stopped: boolean, reason: string|null }} */
function deriveControl(control, { now })                       // state-machine §4.1
/** @returns {{ alive: boolean }} */
function leaseAlive(statusLease, lease, { now })               // L1–L2
/** @returns {{ phase: Record<string, number>, today: number }} */
function launchCounts(statusLaunches, { epoch, now })          // launches since epoch per phase; today = UTC day of now

// execute_plan_state.js
/** @param {object} snapshot  contracts §3.1
 *  @param {object} obs       state-machine §4.0 Observations
 *  @param {{ now: string, actor: 'driver'|'agent', lease: { agent_id, run_id, status } | null, config: object }} opts
 *  @returns {{ state: string, phase: string|null, action: object|null, stop: {reason, detail}|null, evidence: {label,url}[], budgets: object }} */
function decide(snapshot, obs, opts)
function prLadder(pr, ctx)        // exported for unit tests; ctx = { kind: 'phase'|'release'|'sync'|'remedial', draftAction, method, snapshot, obs, opts, control }
```
`decide` must call a single hook for the UAT branch: `if (obs.uat) return decideUat(snapshot, obs, ctx)`
where `decideUat` is imported from `scripts/lib/execute_plan_uat.js`. In WP4a, create that file
with `function decideUat() { return { state: 'release:merged', phase: null, action: { actor:
'driver', kind: 'wait', launch: false, args: { reason: 'preuat' } }, stop: null, evidence: [],
budgets: {} }; }` — WP5 replaces it.

**Rules**
1. Implement state-machine §4.1 and §4.2 rule by rule, in the order written. Put the rule id in a
   comment above each branch (e.g. `// PR-ladder 4`).
2. Agent actions always pass through `applyLeaseRules(action, ctx)` (L3/L4); driver actions never do.
3. `budgets` in the result: `{ failed_attempts: { <phase or "release">: n }, launches_phase: {...},
   launches_today, sync_resolves, remedial_rounds }`.
4. `evidence`: one entry per PR or run the decision looked at (`https://github.com/<repo>/pull/<n>`).
5. On a stop, `action = { actor: 'driver', kind: 'enforce-stop', launch: false, args: { prs: [<open plan PR numbers>] } }`.

**Scenario helper** (`scripts/test/helpers/execute_plan_scenarios.js`): `loadScenario(file)` →
`{ snapshot, obs, opts, expected }` built exactly as state-machine §4.5 describes (`deepMerge`,
`_base.pr.json` under every `pr`, `_base.uat.json` under `uat`, default `opts.config` = contracts §3.8).
The test file iterates all scenario files and asserts `state`, `action.actor`, `action.kind`,
`action.launch`, `action.args.reason` (when `expected.reason` is set), `action.args.method`
(when `expected.method` is set) and `stop?.reason`.

**Tests:** every P/L/S/R/D scenario of state-machine §4.5, plus unit tests `deriveControl order of
reasons`, `leaseAlive with UNKNOWN status uses time only`, `launchCounts ignores launches before epoch`,
`prLadder rules 1–10 each`.

**Acceptance:** `node --test scripts/test/execute_plan_scenarios.test.js && ./scripts/pre-push-changed.sh`

**Docs:** `docs/agent-efficiency/execute-plan-runtime.md` — section "v2 decision logic" that links
to state-machine.md (do not copy the rules).

## WP4b — Observation, `tick`, status comment, `watch-ci`

**Depends on:** WP4a · **Recommended executor:** Claude Code or Cursor · **Size:** ~400 code, ~300 tests

**Files**
- Create: `scripts/lib/execute_plan_status.js`, `scripts/lib/execute_plan_observe.js`,
  `scripts/lib/execute_plan_tick.js`, `scripts/test/execute_plan_status.test.js`,
  `scripts/test/execute_plan_observe.test.js`, `scripts/test/execute_plan_tick.test.js`.
- Modify: `scripts/execute_plan_runtime.js` (register `tick`, `watch-ci`).

**Do not touch:** `execute_plan_state.js` / `execute_plan_control.js` logic (fix bugs there only
with a scenario that proves them), `.github/**`.

**Exports**
```js
// execute_plan_status.js
const STATUS_MARKER = (planId) => `<!-- execute-plan-status:${planId} -->`;
function parseStatusComment(body)              // → status object | null (contracts §3.5)
function formatStatusComment(status, table)    // → full comment body (marker, json block, human table)
function formatLogLine(oldState, newState, url) // `execute-plan: ${old} → ${new} — ${url}`
function applyDecisionToStatus(status, decision, { now, actor }) // pure; returns the next status object

// execute_plan_observe.js
async function loadPlanContext(client, { planId, controlIssue })   // config from main, status comment, init_sha, snapshot at init_sha (WP3 loadSnapshotAtRef)
async function observe(client, ctx, { now })                     // → Observations (state-machine §4.0), uat left null
async function observePr(client, pr, { requiredChecks, epoch })  // → PrObs

// execute_plan_tick.js
/** One tick: load context → observe (+ observeUat when a plan PR into main is merged) → decide → persist → output. */
async function tick(client, { planId, controlIssue, now, actor, lease, dryRun })  // → contracts §3.7 output
async function watchCi(client, { pr, timeoutMin = 25, pollSec = 60, sleep })        // → { timedOut, conclusion, failing: string[] }
```

**Rules**
1. `loadPlanContext` finds the control issue by `--issue <n>` or, when absent, the open issue with
   label `plan:<plan_id>`. Missing config / status comment / `init_sha` → exit `3` with the reason.
2. `observe` fills every field of `Observations` with the sources listed in state-machine §4.0, and
   nothing else. Checks per PR use `config.required_checks.integration` or `.main` by the PR base.
3. Persist (skipped with `dryRun`, which prints the would-be writes):
   a. `applyDecisionToStatus` → update the status comment (bot token; one identity).
   b. If `state` changed → one log comment.
   c. Worker ticks (`actor: 'agent'`) set `status.lease.last_tick_at = now` when a lease exists.
   d. On a stop: label `needs-owner`, `status.stop = { reason, detail, at: now }`. The other parts
      of `enforce-stop` (auto-merge, scope check) are executed by the driver (WP7b).
4. `tick` never executes driver actions itself; it returns them. Workers run only `agent` actions.
5. CLI: `node scripts/execute_plan_runtime.js tick <plan_id> [--issue N] [--json] [--actor agent|driver] [--dry-run]`.
   With `--actor agent`, `lease` is `{ status: 'UNKNOWN' }` (workers have no Cursor key). Exit
   codes per contracts §3.7.
6. `watch-ci <plan_id> --pr <n> [--timeout-min 25]`: polls the head's required check runs; returns
   on completion or timeout; on timeout exits `0` with `timedOut: true` so the worker runs `tick` next.

**Tests:** `parse/format status round trip`, `applyDecisionToStatus records stop`,
`log comment only on state change`, `observe maps a phase PR into PrObs (fake fetch)`,
`failed_attempts counts distinct SHAs after epoch`, `ready_at from timeline`,
`unknown mergeable_state re-read once`, `tick reads snapshot at init_sha not the checkout`,
`tick dry-run performs no writes`, `worker tick refreshes last_tick_at`,
`watch-ci timeout exits 0 with timedOut`.

**Acceptance:** `node --test scripts/test/execute_plan_status.test.js scripts/test/execute_plan_observe.test.js scripts/test/execute_plan_tick.test.js scripts/test/execute_plan_scenarios.test.js && ./scripts/pre-push-changed.sh`

**Docs:** `docs/agent-efficiency/execute-plan-runtime.md` — commands `tick`, `watch-ci`, exit codes;
`docs/agent-efficiency/execute-plan-instruction-stack.md` — short section "v2 loop" at the top
(worker: `tick` → do the agent action → `tick`; stop when actor is driver or stop is set); the
platform table stays until WP10.

## WP5 — UAT stage, watchers, verified `complete-plan`

**Depends on:** WP4b · **Recommended executor:** Claude Code · **Size:** ~400 code, ~250 tests + scenario JSON

**Files**
- Modify: `scripts/lib/execute_plan_uat.js` (replace the WP4a stub), `scripts/lib/execute_plan_tick.js`
  (call `observeUat` when a plan PR into `main` is merged), `scripts/execute_plan_runtime.js`
  (register `watch-preuat`, `watch-deploy`; route `complete-plan` for v2).
- Create: `scripts/lib/execute_plan_uat_observe.js`, `scripts/test/execute_plan_uat.test.js`,
  one JSON file per U scenario in state-machine §4.5 (18 files).

**Do not touch:** `scripts/babysit_uat_watch_preuat.sh` (v1 keeps it until WP10), any workflow,
`scripts/ci/**` (read their outputs, never change them).

**Exports**
```js
// execute_plan_uat.js (pure)
function decideUat(snapshot, obs, ctx)              // state-machine §4.2 U-rules
function classifyDeployFailure(deployRun)          // state-machine §4.4 → 'infra'|'app-smoke'|'unknown'
function isAppCaused(candidate, baseline)          // U3
// execute_plan_uat_observe.js
async function observeUat(client, { mergeSha, mergedAt, source, config, now }) // → UatObservations
function parseProofJobLog(text)                    // → { deploy_ref: string|null, gate_failure_class: string|null }
async function watchPreUat(client, { mergeSha, timeoutMin = 90, pollSec = 120, sleep })
async function watchDeploy(client, { mergeSha, timeoutMin = 45, pollSec = 120, sleep })
async function verifyComplete(client, ctx)         // → { complete: boolean, missing: string|null, evidence: {...} }
```

**Rules**
1. "Contains" is always `compare(merge_sha...candidate).status ∈ {ahead, identical}`. Never match a
   SHA by equality or prefix (B2).
2. `parseProofJobLog`: `deploy_ref` from the first line matching `/DEPLOY_REF:\s*(uat-\d{6}-\d+)/`,
   `gate_failure_class` from `/gate_failure_class=(none|infra_only|code)/` (formats verified on the
   `Prod ready` job log of run 38587026601). No match → `null`.
3. Deploy runs whose `proof_job` is `skipped` are no-ops and never qualify (run 38599483437 is a
   live example: conclusion `success`, every deploy job skipped).
4. `verifyComplete` re-observes and returns `complete: true` only when all four Definition-of-Done
   conditions hold (index §1); `missing` names the first one that does not.
5. `complete-plan <plan_id>` for v2: run `verifyComplete`; if complete → final status comment, log
   comment with the four evidence links, label `plan:complete`, close the issue, exit `0`; else
   exit `2` with `missing`. It never sets a flag on its own. v1 snapshots keep the old behaviour.
6. Watchers poll with the given interval and return `{ timedOut, ...latest observation }`; on
   timeout they exit `0` so the caller runs `tick` next.

**Tests:** every U scenario of state-machine §4.5, plus `parseProofJobLog real format`,
`parseProofJobLog missing lines → nulls`, `isAppCaused subset rule`, `classify infra/app-smoke/unknown`,
`observeUat ignores cancelled runs (fake fetch)`, `observeUat contains via compare`,
`baseline excludes merge_sha itself`, `verifyComplete refuses no-op deploy`,
`complete-plan refuses without deploy`, `remedial merge restarts the stage with the new merge_sha`.

**Acceptance:** `node --test scripts/test/execute_plan_uat.test.js scripts/test/execute_plan_scenarios.test.js && ./scripts/pre-push-changed.sh`

**Docs:** `docs/e2e/uat-deploy-tiers.md` — section "Execute-plan v2 observes this chain" (what is
read, the `Prod ready` proof, at most one Pre-UAT dispatch per `main` head and one Deploy UAT
re-dispatch per tag); `.cursor/skills/babysit-uat/SKILL.md` is changed in WP6a, not here.
