---
title: Execute-plan v2 — observations, state machine, scenarios
owner: Kanopee
audience: agent
status: active
last_updated: 2026-10-15
tags: [agent, execute-plan, autonomy]
---
# Execute-plan v2 — observations, state machine, scenarios

Part of [execute-plan-v2.md](../execute-plan-v2.md). Contracts: [contracts.md](./contracts.md).
Decision code is **pure**: `decide(snapshot, observations, opts)` reads only its arguments.
All GitHub reads happen earlier, in `observe()` / `observeUat()`, which fill the shapes below.

## 4.0 Observation shapes

### `Observations` (filled by `observe()`, WP4b; consumed by `decide()`, WP4a)

Times are ISO-8601 UTC strings. `null` means "does not exist". Example = the scenario base file
`scripts/test/fixtures/execute-plan-v2/scenarios/_base.observations.json` (all phases pending):

```json
{
  "now": "2026-10-16T10:00:00Z",
  "control": {
    "labels": ["execute-plan", "autonomous-approved", "plan:proof-build-label-7f3a"],
    "authorizing": { "comment_id": 9001, "verb": "approve", "valid": true, "invalid_reason": null,
                     "created_at": "2026-10-16T09:05:00Z", "until": "2026-10-23T09:00:00Z" },
    "revoke_comment_at": null,
    "status": null
  },
  "init_sha": "0f1e2d3c4b5a69788796a5b4c3d2e1f00f1e2d3c",
  "main": { "head_sha": "aaaa000000000000000000000000000000000001", "preuat_queued_for_head": false },
  "integration": { "exists": true, "head_sha": "bbbb000000000000000000000000000000000001", "behind_main_by": 0 },
  "phases": [
    { "id": "1", "branch_exists": false, "pr": null },
    { "id": "2", "branch_exists": false, "pr": null }
  ],
  "sync": { "open_pr": null, "resolve_prs_since_epoch": 0 },
  "release": { "pr": null },
  "remedial": { "open_pr": null, "merged_since_epoch": 0 },
  "uat": null
}
```

| Field | Source (WP4b) |
|-------|---------------|
| `control.labels` | `GET /issues/{control_issue}` labels. |
| `control.authorizing` | Latest comment matching APPROVE_RE or RESUME_RE (contracts §3.3), validated; `null` if none. If the latest such comment is invalid, it is reported with `valid: false` and `invalid_reason` ∈ `not-owner`, `bot`, `edited`, `plan`, `hash`, `until`, `window`. |
| `control.revoke_comment_at` | `created_at` of the latest valid REVOKE_RE comment, else `null`. |
| `control.status` | Parsed JSON block of the status comment (contracts §3.5), else `null`. |
| `init_sha` | `control.status.init_sha`; observe fails with exit `3` when absent. |
| `main.preuat_queued_for_head` | A `pre-uat-e2e.yml` run on `main` with `status ∈ {queued, in_progress}` whose `head_sha` = `main.head_sha`. |
| `integration.behind_main_by` | `GET /compare/{integration}...main` → `ahead_by` (commits on `main` not in integration). |
| `phases[i].pr` | Most recent PR with head = `phase.branch`, base = integration (open or merged; ignore closed-unmerged). Shape `PrObs`. |
| `sync.open_pr` | Open PR head `main`, base integration. `resolve_prs_since_epoch` = PRs from `cursor/<id>-sync-*` created after the epoch. |
| `release.pr` | Most recent PR head = integration, base `main` (open or merged). |
| `remedial` | PRs from `cursor/<id>-remedial-*` into `main`: the open one, and the count merged after the epoch. |
| `uat` | `null` until a release or remedial PR of this plan is merged; then `UatObservations` (WP5). |

### `PrObs`

```json
{
  "number": 1950, "node_id": "PR_kwDOexample", "state": "open", "draft": false,
  "merged_at": null, "merge_commit_sha": null,
  "head_ref": "cursor/proof-build-label-7f3a-p1", "head_sha": "cccc000000000000000000000000000000000001",
  "base_ref": "cursor/proof-build-label-7f3a-integration-7f3a",
  "created_at": "2026-10-16T09:20:00Z", "ready_at": "2026-10-16T09:50:00Z",
  "mergeable_state": "clean", "auto_merge_enabled": false, "labels": [],
  "checks": [
    { "name": "ci-gate / CI passed", "status": "completed", "conclusion": "success", "reason": null },
    { "name": "execute-plan-scope", "status": "completed", "conclusion": "success", "reason": "ok" }
  ],
  "failed_attempts_since_epoch": 0,
  "unresolved_threads": [],
  "copilot_review_submitted": false,
  "owner_approved": false
}
```

| Field | Rule |
|-------|------|
| `ready_at` | Latest `ready_for_review` timeline event, else `created_at` when the PR was never a draft, else `null`. |
| `mergeable_state` | From `GET /pulls/{n}`; when GitHub returns `unknown`, observe re-reads once after 3 s, then keeps `unknown`. |
| `checks` | One entry per name in `config.required_checks.integration` (base = integration) or `.main` (base = `main`): the latest check run with that name on `head_sha`. Absent → `{ "status": "missing", "conclusion": null }`. For `execute-plan-scope`, `reason` = the check run `output.title` (`ok`, `unclassified`, `companion-cap`, `drift`, `protected`, `forbidden`, `plan-stopped`, `too-many-files`). |
| `failed_attempts_since_epoch` | Number of **distinct commit SHAs** of the PR (`GET /pulls/{n}/commits`) with at least one required check run concluding `failure`, `timed_out` or `action_required` and `completed_at` after the epoch. One push = one attempt. |
| `unresolved_threads` | GraphQL `reviewThreads(first:100)` where `isResolved == false` → `[{ "url", "path", "author" }]`. |
| `copilot_review_submitted` | A review whose author login starts with `copilot` exists. |
| `owner_approved` | A review in state `APPROVED` by a login in `config.owners`. |

### `UatObservations` (filled by `observeUat()`, WP5; `observations.uat`)

```json
{
  "merge_sha": "dddd000000000000000000000000000000000001",
  "merged_at": "2026-10-17T08:00:00Z",
  "source": { "kind": "release", "pr": 1960 },
  "preuat_runs": [
    { "id": 501, "head_sha": "dddd000000000000000000000000000000000001", "event": "push",
      "status": "completed", "conclusion": "success", "created_at": "2026-10-17T08:01:00Z",
      "updated_at": "2026-10-17T09:10:00Z", "contains_merge": true, "failed_jobs": [] }
  ],
  "baseline_run": null,
  "uat_tags": [ { "name": "uat-261017-1960", "commit_sha": "dddd000000000000000000000000000000000001", "contains_merge": true } ],
  "deploy_runs": [
    { "id": 601, "created_at": "2026-10-17T09:12:00Z", "status": "completed", "conclusion": "success",
      "proof_job": "success", "deploy_job": "success", "smoke_job": "success",
      "deploy_ref": "uat-261017-1960", "deploy_ref_contains_merge": true, "gate_failure_class": "none" }
  ],
  "tier3_run": null
}
```

| Field | Rule |
|-------|------|
| `merge_sha`, `merged_at`, `source` | The most recently merged plan PR into `main` (release, or a remedial PR after it). |
| `preuat_runs` | `pre-uat-e2e.yml` runs on `main` with `created_at ≥ merged_at`, newest first, max 20. `contains_merge` = `compare(merge_sha...head_sha).status ∈ {ahead, identical}`. `failed_jobs` = names of jobs with conclusion `failure`, excluding `config.uat.preuat_gate_job`, sorted. |
| `baseline_run` | Newest completed, non-cancelled `pre-uat-e2e.yml` run whose `head_sha` ≠ `merge_sha` and is an ancestor of `merge_sha` (`compare(head_sha...merge_sha).status == "ahead"`); same shape. |
| `uat_tags` | `GET /tags` (≤ 3 pages of 100), names matching `config.uat.tag_pattern` whose `YYMMDD` ≥ the UTC date of `merged_at`; `commit_sha` from the list (already peeled); `contains_merge` via compare. |
| `deploy_runs` | `deploy-uat.yml` runs with `created_at ≥ merged_at`, newest first, max 10. Job conclusions by name from `config.uat`. For a run whose `proof_job` is `success` or `failure`, read that job's log (`GET /actions/jobs/{id}/logs`): `deploy_ref` from the line `DEPLOY_REF: <tag>` and `gate_failure_class` from `gate_failure_class=<value>` (both verified in a real log, run 38587026601). `deploy_ref_contains_merge` = tag in `uat_tags` with `contains_merge`, else compare. |
| `tier3_run` | Newest `uat-live-e2e.yml` run created after the qualifying deploy run, `{ id, status, conclusion }`, else `null`. |

A Deploy UAT run whose `proof_job` is `skipped` is a **no-op** (Promote skipped; `proceed=false`)
and never counts, even though the run concludes `success` (seen live: run 38599483437).

## 4.1 Control derivation (pure, `deriveControl`, WP3)

```
epoch            = control.authorizing.valid ? control.authorizing.created_at : null
deadline         = control.authorizing.valid ? control.authorizing.until : null
revoked          = labels has "autonomous-revoked" OR (revoke_comment_at != null AND revoke_comment_at > epoch)
escalated        = labels has "needs-owner"
stale_stop       = status.stop != null AND status.stop.at <= epoch      (ignored)
```

Stopped when the first of these holds (this is the STOP reason): `approval-invalid`
(`authorizing` null or `valid == false`), `revoked`, `escalation` (label `needs-owner` present
and no `status.stop` newer than the epoch), the recorded `status.stop.reason` (when
`status.stop.at > epoch`), `expired` (`now ≥ deadline`).

**L-rules (lease and launches):**
- L1 `RUNNING_SET = {CREATING, RUNNING}` (same as `.github/scripts/monitor-cursor-agent.js:25`).
- L2 The lease is **alive** iff `opts.lease` is non-null, `opts.lease.status ∈ RUNNING_SET` and
  `now − status.lease.last_tick_at < 20 min`. When `opts.lease.status` is `UNKNOWN` (no Cursor
  key, e.g. worker ticks), only the time test applies.
- L3 `opts.actor == "agent"` (worker tick): agent actions are returned with `launch: false` — the
  caller is the worker and does the action itself.
- L4 `opts.actor == "driver"`: an agent action becomes `wait(agent-alive)` when the lease is
  alive; otherwise it gets `launch: true` if `launches for this phase since the epoch <
  launches_per_phase` **and** `launches today (UTC) < daily_launches`; otherwise STOP
  `launch-budget`.

## 4.2 Decision rules (`decide`, first matching rule wins)

Rule ids are normative; every scenario cites one.

**D — control.** D1 stopped (§4.1) → `stop: { reason }`, action `enforce-stop` with all open plan
PRs. D2 `uat != null` → **U-rules**. D3 release PR open → **PR-ladder** on it (method `squash`,
draft action `implement` is not used — a release PR is never draft). D4 all phases merged →
**S-rules**. D5 otherwise → **P-rules**.

**P — phases.** P1 current phase = first phase whose `pr.merged_at` is null. P2 `pr == null` and
`branch_exists == false` → driver `create-phase-branch` (from `integration.head_sha`). P3 `pr ==
null` and branch exists → agent `implement` (L-rules). P4 `pr` exists → PR-ladder, draft action
`implement`, method `squash`.

**S — sync and release (all phases merged).** S1 `release.pr == null` and `behind_main_by > 0`:
S1a no open sync PR → driver `open-sync-pr`; S1b sync PR `mergeable_state == "dirty"` →
`resolve_prs_since_epoch ≥ sync_attempts` ? STOP `sync-conflict` : agent `resolve-sync` (branch
`cursor/<id>-sync-<resolve_prs_since_epoch + 1>`); S1c otherwise → PR-ladder on the sync PR with
method `merge` (scope is always green for sync PRs). S2 `release.pr == null` and `behind_main_by
== 0` → driver `open-release-pr`.

**PR-ladder** (applied to one PR; "attempts" = `failed_attempts_since_epoch`):
1. Label `do-not-merge` → STOP `pr-blocked`.
2. `draft` → the draft action (agent, L-rules).
3. Scope check `reason ∈ {drift, protected, forbidden}` → STOP `drift`.
4. Any required check concluded `failure`/`timed_out`/`action_required` on `head_sha`:
   attempts ≥ `ci_per_phase` → STOP `ci-budget`; else, when the only failing check is
   `execute-plan-scope` with reason `unclassified`/`companion-cap`/`too-many-files` → agent
   `fix-scope`; else agent `fix-ci` (L-rules).
5. `unresolved_threads` non-empty → agent `triage-review` (L-rules).
6. `mergeable_state == "dirty"` → release PR: driver `open-sync-pr`; other PRs: agent
   `resolve-conflict` (L-rules).
7. `mergeable_state == "behind"` → driver `update-branch`.
8. Release PR and `settings.release_owner_review` and not `owner_approved` → `wait(owner-review)`.
9. `auto_merge_enabled == false`: base `main` and not `copilot_review_submitted` and
   `now − ready_at < 15 min` → `wait(copilot)`; else driver `arm-auto-merge`.
10. Otherwise → `wait(checks)`.

**U — UAT stage** (`uat` non-null; `C` = newest `preuat_runs` entry with `contains_merge` and
`status == "completed"` and `conclusion ∉ {cancelled, skipped}`).
- U1 `remedial.open_pr` → PR-ladder on it (method `squash`, draft action `remedial`).
- U2 no `C`: (`main.preuat_queued_for_head` or `now − merged_at < 10 min`) → `wait(preuat)`;
  else `main.head_sha ∉ status.dispatched.preuat_heads` → driver `dispatch-preuat`; else
  `wait(preuat-dispatched)`.
- U3 `C.conclusion == "failure"`: app-caused ⇔ `baseline_run == null` or baseline
  `conclusion == "success"` or `C.failed_jobs ⊄ baseline.failed_jobs`. App-caused →
  `remedial.merged_since_epoch ≥ remedial_rounds` ? STOP `preuat-budget` : agent `remedial`
  (branch `cursor/<id>-remedial-<merged_since_epoch + 1>`, failing = `C.failed_jobs`). Not
  app-caused → `now − C.updated_at ≥ 6 h` ? STOP `main-red` : `wait(main-green)`.
- U4 `C` success and no `uat_tags` entry with `contains_merge` → same as U2 with reason `promote`
  (wait while a run for `main` head is queued, else dispatch once per head).
- U5 tag exists; `D` = newest `deploy_runs` entry with `proof_job ∈ {success, failure}` and
  `deploy_ref_contains_merge == true`. No `D` → `wait(deploy)`.
- U6 `D.proof_job == "success"`: if `tier3_blocking` and `tier3_run?.conclusion != "success"` →
  `tier3_run?.conclusion == "failure"` ? STOP `tier3-red` : `wait(tier3)`; else state
  `complete`, driver `complete-plan`.
- U7 `D.proof_job == "failure"` → class (§4.4): `infra` → `D.deploy_ref ∉
  dispatched.deploy_tags` ? driver `dispatch-deploy` : STOP `uat-infra`; `app-smoke` → as an
  app-caused U3 (failing = `["deploy-smoke"]`); `unknown` → STOP `uat-unknown`.

State names written to the status comment: `stopped`, `phase:pending`, `phase:implementing`,
`phase:ready`, `phase:merged`, `sync`, `release:open`, `release:merged`, `awaiting-preuat`,
`remedial`, `awaiting-main-green`, `awaiting-promote`, `awaiting-deploy`, `complete`.

## 4.3 STOP reasons (fixed list — nothing else stops a run)

| Reason | Rule |
|--------|------|
| `approval-invalid` | §4.1 — no valid authorizing comment, or it was edited/deleted, or the plan files at `init_sha` no longer hash to `approval_hash` |
| `revoked` | §4.1 |
| `escalation` | §4.1 — `needs-owner` added by a human |
| `expired` | §4.1 — `now ≥` effective deadline |
| `drift` | PR-ladder 3 |
| `ci-budget` | PR-ladder 4 |
| `launch-budget` | L4 |
| `pr-blocked` | PR-ladder 1 |
| `sync-conflict` | S1b |
| `preuat-budget` | U3 / U7 |
| `main-red` | U3 |
| `uat-infra` | U7 |
| `uat-unknown` | U7 |
| `tier3-red` | U6 (only when `tier3_blocking`) |

## 4.4 Deploy UAT failure classes (`classifyDeployFailure`, pure)

Uses the existing repo classification (`scripts/ci/assert-uat-gates.sh:109-124`), read from the
`Prod ready` job log:

| Class | Condition | Handling |
|-------|-----------|----------|
| `infra` | `gate_failure_class == "infra_only"` | one `dispatch-deploy` per tag, then STOP `uat-infra` |
| `app-smoke` | `gate_failure_class == "code"` and `deploy_job == "success"` and `smoke_job == "failure"` | remedial (budget `remedial_rounds`) |
| `unknown` | anything else (build failure, migration gate, missing log line) | STOP `uat-unknown` |

## 4.5 Scenario tests (pure, hand-written; no recorded GitHub traffic)

Runner: `scripts/test/execute_plan_scenarios.test.js` loads every `*.json` in
`scripts/test/fixtures/execute-plan-v2/scenarios/` except files starting with `_`, builds inputs,
calls `decide`, and asserts `expected`. Scenario file format:

```json
{
  "name": "ready → arm-auto-merge",
  "rule": "PR-ladder 9",
  "snapshot_patch": {},
  "observations_patch": { "phases": [ { "id": "1", "branch_exists": true, "pr": { "number": 1950, "draft": false } }, { "id": "2", "branch_exists": false, "pr": null } ] },
  "opts": { "actor": "driver", "lease": null, "now": "2026-10-16T10:30:00Z" },
  "expected": { "state": "phase:ready", "actor": "driver", "kind": "arm-auto-merge", "launch": false, "stop": null }
}
```

Building inputs: `snapshot = deepMerge(_base.snapshot.json, snapshot_patch)`; `observations =
deepMerge(_base.observations.json, observations_patch)`; every `pr` object in the patch is first
merged onto `_base.pr.json` (the `PrObs` example above), and `uat` onto `_base.uat.json` (the
`UatObservations` example). `deepMerge`: plain objects merge key by key; arrays and scalars
replace. `_base.snapshot.json` = contracts §3.1 object. `opts.config` defaults to contracts §3.8.

Required scenarios (file name → expected `state` / `actor kind` or `stop`; WP4a writes P/S/D/L,
WP5 writes U):

| File | Rule | Expected |
|------|------|----------|
| `p-pending-create-branch.json` | P2 | `phase:pending` / driver `create-phase-branch` |
| `p-branch-launch-implement.json` | P3, L4 | `phase:pending` / agent `implement`, launch true |
| `p-draft-lease-alive-wait.json` | PR-ladder 2, L2 | `phase:implementing` / driver `wait` (`agent-alive`) |
| `p-draft-lease-stale-relaunch.json` | PR-ladder 2, L2 | `phase:implementing` / agent `implement`, launch true |
| `p-worker-tick-no-launch.json` | L3 | agent `implement`, launch false |
| `p-ready-arm-auto-merge.json` | PR-ladder 9 | `phase:ready` / driver `arm-auto-merge` |
| `p-ready-red-fix-ci.json` | PR-ladder 4 | `phase:ready` / agent `fix-ci` |
| `p-scope-unclassified-fix-scope.json` | PR-ladder 4 | agent `fix-scope` |
| `p-scope-drift-stop.json` | PR-ladder 3 | stop `drift` |
| `p-ci-budget-stop.json` | PR-ladder 4 | stop `ci-budget` |
| `p-threads-triage.json` | PR-ladder 5 | agent `triage-review` |
| `p-dirty-resolve-conflict.json` | PR-ladder 6 | agent `resolve-conflict` |
| `p-auto-merge-armed-wait.json` | PR-ladder 10 | driver `wait` (`checks`) |
| `p-merged-next-phase.json` | P1–P2 | phase 2 / driver `create-phase-branch` |
| `p-do-not-merge-stop.json` | PR-ladder 1 | stop `pr-blocked` |
| `l-launch-budget-phase-stop.json` | L4 | stop `launch-budget` |
| `l-daily-cap-stop.json` | L4 | stop `launch-budget` |
| `s-behind-open-sync.json` | S1a | `sync` / driver `open-sync-pr` |
| `s-sync-dirty-resolve.json` | S1b | agent `resolve-sync` |
| `s-sync-budget-stop.json` | S1b | stop `sync-conflict` |
| `s-sync-clean-arm-merge.json` | S1c | driver `arm-auto-merge` method `merge` |
| `s-open-release.json` | S2 | driver `open-release-pr` |
| `r-release-behind-update.json` | PR-ladder 7 | `release:open` / driver `update-branch` |
| `r-release-copilot-wait.json` | PR-ladder 9 | driver `wait` (`copilot`) |
| `r-release-owner-review-wait.json` | PR-ladder 8 | driver `wait` (`owner-review`) |
| `r-release-dirty-sync.json` | PR-ladder 6 | driver `open-sync-pr` |
| `d-revoked-label-stop.json` | D1 | stop `revoked`, action `enforce-stop` |
| `d-revoke-comment-then-resume.json` | §4.1 | not stopped (resume newer than revoke) |
| `d-approval-edited-stop.json` | D1 | stop `approval-invalid` |
| `d-expired-stop.json` | D1 | stop `expired` |
| `d-resume-clears-stop-and-budget.json` | §4.1 | old `ci-budget` stop ignored; attempts counted after the epoch |
| `d-replay-1895-ready.json` | PR-ladder 9 | the 2026-10-14 situation (phase PR ready, CI green, no threads) → driver `arm-auto-merge`, not a stop |
| `u-merged-wait-preuat.json` | U2 | `awaiting-preuat` / driver `wait` (`preuat`) |
| `u-preuat-cancelled-still-waiting.json` | U2 | cancelled runs ignored |
| `u-nothing-queued-dispatch.json` | U2 | driver `dispatch-preuat` |
| `u-dispatched-once.json` | U2 | driver `wait` (`preuat-dispatched`) |
| `u-red-app-remedial.json` | U3 | `remedial` / agent `remedial` |
| `u-red-baseline-red-wait.json` | U3 | `awaiting-main-green` / driver `wait` (`main-green`) |
| `u-main-red-6h-stop.json` | U3 | stop `main-red` |
| `u-remedial-budget-stop.json` | U3 | stop `preuat-budget` |
| `u-green-head-moved-promote-wait.json` | U4 | `awaiting-promote` / driver `wait` (`promote`) |
| `u-tag-wait-deploy.json` | U5 | `awaiting-deploy` / driver `wait` (`deploy`) |
| `u-noop-deploy-ignored.json` | U5 | `proof_job: skipped` run ignored → `wait` (`deploy`) |
| `u-deploy-infra-redispatch.json` | U7 | driver `dispatch-deploy` |
| `u-deploy-infra-twice-stop.json` | U7 | stop `uat-infra` |
| `u-deploy-app-smoke-remedial.json` | U7 | agent `remedial` |
| `u-deploy-unknown-stop.json` | U7 | stop `uat-unknown` |
| `u-complete.json` | U6 | `complete` / driver `complete-plan` |
| `u-tier3-blocking-wait.json` | U6 | driver `wait` (`tier3`) |
| `u-remedial-open-ladder.json` | U1 | PR-ladder on the remedial PR |
