# WEIGHT child A — server: one weight service, weigh-in integrity, counting a weight as a weigh-in

> **Child of** [`weight-monitoring-unify-9b2e`](./weight-monitoring-unify-9b2e.md). **All rules, contracts, tests and copy are in the roadmap.** This file holds the phase table and runtime state only. Read roadmap §0 before starting.

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `weight-unify-server-9b2e` |
| **parent** | `weight-monitoring-unify-9b2e` (roadmap; W0 runs there as a docs PR to `main` before this child) |
| **base_branch** | `cursor/weight-unify-server-integration-9b2e` (create from a fresh `origin/main` at bootstrap) |
| **control issue** | [#1557](https://github.com/KanopeeKa/AgathaCheck/issues/1557) (standing grant from roadmap #1537) |
| **landing** | integration → `main` PR, `/babysit-uat` until pre-UAT green, then the landing broadcast (roadmap §10.4) |
| **entry gate** | roadmap §10.1: W0 merged on `main`; PEOPLE `people-server-7f3b` not in progress; no ARCH PR open on the weight routes, `healthEntries` routes or `pets/coreRouter.js`; no other programme `main` PR open at landing |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Phases

| id | Title | Branch | Spec | exit_checklist |
|---|---|---|---|---|
| `W1` | Migration, units and dates, shared weight service (on ARCH E's transaction code), user unit preference, pet create/update through the service | `cursor/weight-unify-w1-service-9b2e` | §5.1–§5.4, §5.7, tests U-1…U-11, P-1…P-4 | `single-backend-route` |
| `W2` | Weigh-in integrity: undo, one date, skip reasons, occurrence detail | `cursor/weight-unify-w2-integrity-9b2e` | §5.5, tests L-1…L-12 | `single-backend-route` |
| `W3` | Counting a weight as a weigh-in: rule, candidates, fulfil, overview | `cursor/weight-unify-w3-fulfil-9b2e` | §5.6, tests F-1…F-22 | `single-backend-route` |
| `W4` | BDD and Playwright for the server landing | `cursor/weight-unify-w4-e2e-9b2e` | §8.5 (W4 rows) | `bdd-journey` |

`allowed_paths` / `forbidden_paths` / `allowed_exceptions` per phase: see `weight-unify-server-9b2e.snapshot.json`.

**Exit (child):** roadmap §10.1 Exit.

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: W1
last_completed_phase: null
halt_reason: null
next_action: "continue phase W1 on branch cursor/weight-unify-w1-service-9b2e"
artifact_ref:
  branch: cursor/weight-unify-w1-service-9b2e
  plan_path: .agents/plans/weight-unify-server-9b2e.md
  plan_commit: 373061cae4f5bf8c9dccb03d10e5dd9c54cd10e5
  snapshot_path: .agents/plans/weight-unify-server-9b2e.snapshot.json
  snapshot_commit: 373061cae4f5bf8c9dccb03d10e5dd9c54cd10e5
open_prs: [true]
merge_commits: {}
debt_issue_refs: []
```
