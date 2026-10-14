---
title: Execute-plan v2 — data contracts and state machine
owner: Kanopee
audience: agent
status: active
last_updated: 2026-10-15
tags: [agent, execute-plan, autonomy]
---
# Execute-plan v2 — data contracts and state machine

Part of [execute-plan-v2.md](../execute-plan-v2.md). Normative for WP1–WP8.

## 3.1 Snapshot v2 (`.agents/plans/<plan_id>.snapshot.json`)

Every field is immutable after approval. There are **no runtime fields**; progress is derived from
GitHub (§4). This exact object is the worked example used by the hash test vector in §3.4.

```json
{
  "schema_version": 2,
  "plan_id": "proof-build-label-7f3a",
  "title": "Proof run: UAT build label",
  "plan_file": ".agents/plans/proof-build-label-7f3a.md",
  "plan_file_sha256": "3b1f0d7c1a4e2f9b8c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b",
  "base_branch": "main",
  "integration_branch": "cursor/proof-build-label-7f3a-integration-7f3a",
  "control_issue": 1900,
  "created_at": "2026-10-16T09:00:00Z",
  "approved_until": "2026-10-23T09:00:00Z",
  "settings": {
    "release_owner_review": false,
    "tier3_blocking": false,
    "budgets": { "ci_per_phase": 3, "launches_per_phase": 3, "remedial_rounds": 3, "sync_attempts": 2, "daily_launches": 10 }
  },
  "protected_paths_version": 1,
  "phases": [
    { "id": "1", "title": "Server build label", "branch": "cursor/proof-build-label-7f3a-p1",
      "allowed_paths": ["server/routes/health.js", "server/test/health.test.js"],
      "forbidden_paths": [], "allowed_exceptions": ["tests"], "companions": [],
      "exit_checklist": ["health test green"] },
    { "id": "2", "title": "Docs note", "branch": "cursor/proof-build-label-7f3a-p2",
      "allowed_paths": ["docs/e2e/uat-deploy-tiers.md"],
      "forbidden_paths": [], "allowed_exceptions": ["docs"], "companions": [],
      "exit_checklist": ["docs gate green"] }
  ],
  "approval_hash": "sha256:8d756032dc395b22e1de899ce1b3d37d51e147ed270195290a44c3c997c70717"
}
```

| Field | Rule |
|-------|------|
| `schema_version` | `2`. v1 files (absent or `1`) are routed to the v1 code paths untouched. |
| `plan_id` | `^[a-z0-9][a-z0-9-]{2,48}$`; equals the file stem. |
| `plan_file`, `plan_file_sha256` | Path and SHA-256 (hex, lower) of the plan markdown bytes at `init`. Covered by the hash (B4). |
| `base_branch` | Always `main` for v2 (multi-phase on `main` is rejected, as in v1). |
| `integration_branch` | Must match `^cursor/<plan_id>-integration-[a-z0-9]{4}$` so `ci.yml:10-13` and the ruleset pattern apply. |
| `control_issue` | Issue number created by `init` before the hash is computed. |
| `approved_until` | ISO-8601 UTC, `created_at + window_days`; must equal the `until` in the approval comment; ≤ cap (14 d). |
| `settings.budgets.*` | Each ≤ cap in `execute_plan_constants.js`; validation rejects higher values. |
| `protected_paths_version` | Version of the protected set in `execute_plan_scope.js`; the scope check uses the set from `main`, not from the snapshot. |
| `phases[]` | Ordered; one PR each; `branch` matches `^cursor/<plan_id>-p<n>$`; `allowed_exceptions` ⊆ `{tests, docs}`; `companions` are extra globs, ≤ 5 per phase. |
| `approval_hash` | §3.4. The only field excluded from its own input. |

## 3.2 Plan file (`.agents/plans/<plan_id>.md`)

Human-readable scope the workers follow. Required headings, in order: `# <title>`, `## Goal`,
`## Phases` (one `### Phase <id> — <title>` per snapshot phase, each with `Scope`, `Out of scope`,
`Exit checklist`), `## Proof on UAT` (how the result is observed). It must **not** contain process
rules (no "stop", "halt", "run until" prose) — `validate_execute_plan_snapshot.js` rejects a plan
file containing a `## Contract` / `## Rules` heading (WP3). Immutable after approval: any plan-
category PR that changes `.agents/plans/<plan_id>.*` is `drift`.

## 3.3 Approval, revocation, escalation (control-issue grammar)

Approval comment body, after `trim()`, must match exactly (one line):

```
^approve-autonomous (?<plan>[a-z0-9][a-z0-9-]{2,48}) sha256:(?<hash>[0-9a-f]{64}) until (?<until>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)$
```

An approval is **valid** only if all hold: `comment.user.login` ∈ `owners` of
`.github/execute-plan.config.json` on `main`; `author_association == "OWNER"`; login ≠
`bot_login`; `created_at == updated_at` (never edited); `plan` equals the snapshot `plan_id`;
`hash` equals the snapshot `approval_hash`; `until` equals `approved_until`; `until − now ≤ cap`.
Edited or deleted approval comments invalidate the approval (STOP `approval-invalid`).

Revocation: comment `revoke-autonomous <plan_id>` by an owner **or** label `autonomous-revoked`.
Escalation by the owner: label `needs-owner` (also set by `tick` on every STOP). Labels applied by
the approve workflow: `autonomous-approved`, `plan:<plan_id>`. Removed by the owner only.

## 3.4 `approval_hash`

```
input  = snapshot object with the key "approval_hash" removed
canon  = canonical(input)      // see below
hash   = "sha256:" + hex(SHA-256(UTF-8(canon)))
```

`canonical(v)`: arrays → `[` + elements joined by `,` + `]`; objects → `{` + entries sorted by
key (byte order), each `JSON.stringify(key) + ":" + canonical(value)`, joined by `,` + `}`; all
other values → `JSON.stringify(v)`. No whitespace. `plan_file_sha256` inside the input binds the
markdown (B4).

Test vectors (`scripts/test/execute_plan_approval.test.js`):

| Input | `canonical` | Hash |
|-------|-------------|------|
| `{}` | `{}` | `sha256:44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a` |
| `{b:1,a:[true,null,"x"]}` | `{"a":[true,null,"x"],"b":1}` | `sha256:54a65415ad370228851a1da4b31b6fd42dc58b19a50d35cae759325f7388ce64` |
| §3.1 object minus `approval_hash` | 1126 bytes, starts `{"approved_until":"2026-10-23T09:00:00Z","base_branch":"main",` | `sha256:8d756032dc395b22e1de899ce1b3d37d51e147ed270195290a44c3c997c70717` |

## 3.5 Status comment (one per control issue, bot-owned, edited in place)

```
<!-- execute-plan-status:<plan_id> -->
```json
{ "schema": 1, "plan_id": "…", "state": "phase:implementing", "phase": "1",
  "lease": { "agent_id": "…", "launched_at": "…", "last_tick_at": "…", "platform": "cursor" } | null,
  "budgets": { "ci": { "1": 1, "release": 0 }, "launches": { "1": 2 }, "remedial": 0, "sync": 0, "launches_today": { "2026-10-16": 2 } },
  "release": { "pr": 1950, "merge_sha": "…" } | null,
  "uat": { "preuat_run": 123, "tag": "uat-2026-10-17-1", "deploy_run": 456, "tier3": "pending|success|failure" } | null,
  "stop": { "reason": "…", "detail": "…", "at": "…" } | null,
  "updated_at": "…" }
```
| Phase | Branch | PR | State | CI used | Launches |
|…human table…|
```

Rules: `tick` finds the comment by the marker, creates it once, and edits it afterwards. One
additional **log comment per state transition** (`execute-plan: <old> → <new> — <evidence url>`).
`tick` posts nothing else (R6). The lease is alive only if the Cursor agent status ∈
`{CREATING, RUNNING}` (as in `.github/scripts/monitor-cursor-agent.js`) **and** `last_tick_at` is
less than 20 minutes old (R5). Budget counters that GitHub can derive (CI attempts = failed
`ci-gate / CI passed` check runs on the PR's commits; remedial rounds = merged remedial PRs) are
recomputed from GitHub on every tick; only launches and sync attempts are stored.

## 3.6 Handoff prompt (worker launch and relaunch)

```
/execute-plan <plan_id>

You are a worker for execute-plan <plan_id>. Do exactly the action below, then run
`node scripts/execute_plan_runtime.js tick <plan_id> --json` and continue with what it returns,
until it returns an action whose actor is "driver" or a stop. Then end your turn with one line.

Action: <kind> — <one-line description>
Branch: <branch>   Base: <base>   PR: <#n or none>   Phase: <id> "<title>"
Scope (allowed): <allowed_paths joined>   Companions: <companions>   Forbidden: protected set + <forbidden_paths>
Evidence: <failing check names / unresolved thread urls / conflict files, as applicable>
Plan file: .agents/plans/<plan_id>.md (read it first; do not edit it or the snapshot)

Rules: open a draft PR into <base> right after your first commit; push often; mark the PR ready
only after ./scripts/pre-push-changed.sh is green; never touch protected paths; never approve,
label or merge anything; never edit the control issue except through tick.
```

## 3.7 `tick` output (`--json`)

```json
{ "schema": 1, "plan_id": "…", "state": "release:open",
  "action": { "actor": "driver" | "agent", "kind": "fix-ci", "args": { "pr": 1950, "branch": "…", "failing": ["ci-gate / CI passed"] } } | null,
  "stop": { "reason": "ci-budget", "detail": "phase 1: 3/3 CI attempts used" } | null,
  "evidence": [ { "label": "release PR", "url": "…" } ],
  "budgets": { … as in the status comment … } }
```
Exit codes: `0` action or complete, `2` stop, `3` approval/config error. Exactly one of
`action`/`stop` is non-null unless `state == "complete"` (both null).

| Actor | Kind | Args | When |
|-------|------|------|------|
| agent | `implement` | phase, branch, base | phase pending or implementing without ready PR |
| agent | `fix-ci` | pr, failing check names | ready PR with failed required check, budget left |
| agent | `triage-review` | pr, unresolved thread urls | ready PR with unresolved threads |
| agent | `fix-scope` | pr, violations (file, reason) | `execute-plan-scope` red for `unclassified` or companion cap; counts as a CI attempt (`drift`/`protected` are a STOP, not an action) |
| agent | `resolve-sync` | sync pr, conflict files, branch `cursor/<id>-sync-N` | sync PR not mergeable |
| agent | `remedial` | failing shards, baseline run, branch `cursor/<id>-remedial-N` | Pre-UAT app-caused red |
| driver | `arm-auto-merge` | pr, method (`squash`/`merge`) | ready PR, green or pending checks, no unresolved threads |
| driver | `merge-now` | pr, method | auto-merge refused because the PR is already clean |
| driver | `update-branch` | pr | PR behind a `strict` base |
| driver | `open-sync-pr` / `open-release-pr` | head, base | integration behind `main` / all phases merged |
| driver | `rerun-ci` | run id | job failed before tests started; once per head SHA |
| driver | `dispatch-preuat` | — | no Pre-UAT run for `main` HEAD queued or running ≥ 10 min after merge |
| driver | `disable-auto-merge` | prs[] | on every STOP and on revoke |
| driver | `wait` | until / reason | anything pending |

## 4. State machine

Observation endpoints: PRs `GET /repos/{o}/{r}/pulls?state=all&head={o}:{branch}&base={base}`;
check runs `GET /repos/{o}/{r}/commits/{sha}/check-runs`; compare
`GET /repos/{o}/{r}/compare/{base}...{head}` (`status`, `files`); workflow runs
`GET /repos/{o}/{r}/actions/workflows/{file}/runs?branch=main`; tags `GET /repos/{o}/{r}/tags`;
threads: GraphQL `pullRequest.reviewThreads(isResolved:false)`. "X contains Y" ⇔
`compare(Y...X).status ∈ {ahead, identical}` (B2).

| State | Defining observation | Next action (actor) | Budget |
|-------|---------------------|---------------------|--------|
| `stopped` | status comment has `stop`, or label `autonomous-revoked` / `needs-owner`, or approval invalid, or `now ≥ approved_until` | `disable-auto-merge` then none | — |
| `phase:pending` | no merged PR for this phase; branch absent | `implement` (agent) | launches |
| `phase:implementing` | branch exists; PR absent or draft | `implement` (agent, relaunch only if lease dead) | launches |
| `phase:ready` | PR ready; required checks pending/green; no unresolved threads | `arm-auto-merge` squash (driver) / `merge-now` | — |
| `phase:ready` + red | a required check run `failure` on head | `fix-ci` (agent) | ci |
| `phase:ready` + threads | unresolved review threads | `triage-review` (agent) | — |
| `phase:merged` | PR head = phase branch, base = integration, `merged_at` set | next phase | — |
| `sync` | all phases merged, no release PR, `compare(main...integration).behind_by > 0` | `open-sync-pr` (driver, merge commit); not mergeable → `resolve-sync` (agent) | sync |
| `release:open` | PR integration→`main` open | as `phase:ready` rules, method squash, `update-branch` when behind; if `release_owner_review` → `wait` for owner approval | ci (`release`) |
| `release:merged` | release PR merged → `merge_sha` | enter UAT stage | — |
| `awaiting-preuat` | no completed Pre-UAT run whose head contains `merge_sha`; one queued/running, or merge < 10 min ago | `wait`; after 10 min with nothing queued → `dispatch-preuat` | — |
| `remedial` | latest completed Pre-UAT run containing `merge_sha` is `failure` **and** its failing shards ⊄ failing shards of the baseline run (latest completed run whose head is an ancestor of `merge_sha`, baseline green or red) | `remedial` (agent) → remedial PR to `main` → `release:open` rules → new `merge_sha` | remedial |
| `awaiting-main-green` | latest Pre-UAT run containing `merge_sha` is `failure` and the baseline run is `failure` with the same shards | `wait` ≤ 6 h | — |
| `awaiting-promote` | green Pre-UAT run contains `merge_sha`; no `uat-*` tag contains `merge_sha` | `wait` while a run for `main` HEAD is queued/running; else `dispatch-preuat` | — |
| `awaiting-deploy` | tag exists; no Deploy UAT run with `success` containing `merge_sha` created after `merged_at` | `wait`; `failure` → classify (§4.2) | — |
| `complete` | all four DoD conditions | none; `tick` closes the control issue and writes the final status | — |

Cancelled Pre-UAT runs are ignored (treated as not completed). A phase's PR is "the" PR = the
most recent PR with that head/base; older closed-unmerged PRs are ignored.

### 4.1 STOP reasons (fixed list; nothing else stops a run)

| Reason | Exact condition |
|--------|-----------------|
| `revoked` | label `autonomous-revoked` or a valid `revoke-autonomous <id>` comment |
| `expired` | `now ≥ approved_until` |
| `approval-invalid` | no valid approval comment (§3.3), or the approval comment was edited/deleted, or the snapshot/plan on the integration branch no longer hashes to `approval_hash` |
| `drift` | a plan-category PR changes `.agents/plans/<id>.*`, or its files include a protected path |
| `ci-budget` | failed required check runs on one phase/release PR ≥ `ci_per_phase` |
| `launch-budget` | launches for one phase ≥ `launches_per_phase`, or launches today ≥ `daily_launches` |
| `sync-conflict` | sync attempts ≥ `sync_attempts` |
| `preuat-budget` | remedial rounds ≥ `remedial_rounds` |
| `main-red` | `awaiting-main-green` for more than 6 h |
| `uat-infra` | Deploy UAT failure in an infra class (§4.2) after its single re-dispatch |
| `uat-unknown` | Deploy UAT failure not in the class table |
| `release-blocked` | release PR not mergeable for a reason other than checks/threads/behind (e.g. owner `do-not-merge` label) |
| `escalation` | label `needs-owner` applied by a human |

On every STOP: `disable-auto-merge` on all open plan PRs, label `needs-owner`, status comment
`stop` set, one log comment. The scope check reads the same state and turns **red** for every open
plan PR (B3), so nothing can land after a STOP.

### 4.2 Deploy UAT failure classes

Classify by the failing job/step names and outputs of `deploy-uat.yml` (**VERIFY** names before
coding: `rg -n "^\s+(id|name):" .github/workflows/deploy-uat.yml`):

| Class | Signal | Handling |
|-------|--------|----------|
| infra-transient | SSH/connection steps (`ssh_enforcement`, `assert_ssh_proofs`) failed, smoke never ran | one `dispatch deploy-uat` with `deploy_ref` = tag; second failure → STOP `uat-infra` |
| infra-migration | `uat_deploy_state` outputs `migrate_pending_count > 0` or `UAT_AUTO_MIGRATE` gate | STOP `uat-infra` (human ops, `docs/e2e/uat-promote-manual.md`) |
| app-smoke | `smoke` job failed (`uat-post-deploy-smoke.sh`) and the release changed `server/**` | `remedial` (counts a remedial round) |
| unknown | anything else | STOP `uat-unknown` |

### 4.3 Transition tests (names are normative; `scripts/test/execute_plan_state.test.js`)

`pending→implementing`, `implementing→ready (draft marked ready)`, `ready→arm-auto-merge`,
`ready red→fix-ci`, `ready threads→triage-review`, `ready→merged→next phase`,
`last phase merged→sync (behind)`, `sync not mergeable→resolve-sync`,
`sync merged→open-release-pr`, `release behind strict→update-branch`,
`release merged→awaiting-preuat`, `preuat cancelled→still awaiting`,
`preuat red app→remedial`, `preuat red baseline red→awaiting-main-green`,
`awaiting-main-green 6h→STOP main-red`, `preuat green HEAD moved→awaiting-promote wait`,
`awaiting-promote nothing queued→dispatch-preuat`, `tag→awaiting-deploy`,
`deploy infra-transient→redispatch once`, `deploy unknown→STOP uat-unknown`,
`deploy success→complete`, `revoke mid-release→STOP + disable-auto-merge`,
`approval edited→STOP approval-invalid`, `replay-1894-1895→continue (babysit) not stop`,
`budget ci exhausted→STOP`, `launch budget exhausted→STOP`, `plan lowers budget ok / raises→invalid`.
