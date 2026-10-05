# WEIGHT child C — care side: weigh-in unit and skip reasons, weight section on the care item view, legacy weigh-in path removed

> **Child of** [`weight-monitoring-unify-9b2e`](./weight-monitoring-unify-9b2e.md). **All rules, contracts, tests and copy are in the roadmap.** This file holds the phase table and runtime state only. Read roadmap §0 before starting.

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `weight-unify-care-9b2e` |
| **parent** | `weight-monitoring-unify-9b2e` (roadmap) |
| **base_branch** | `cursor/weight-unify-care-integration-9b2e` (create from a fresh `origin/main` after child B has landed) |
| **control issue** | own issue, created at bootstrap under the roadmap's standing grant (roadmap §11.1); placeholder `999999` until then |
| **landing** | integration → `main` PR, `/babysit-uat` until pre-UAT green, then the landing broadcast (roadmap §10.4) and `complete-plan` on the roadmap |
| **entry gate** | roadmap §10.3: child B landed; ARCH G phase 3 (`health_tracking/presentation/widgets/**`, `screens/**`, `care_schedule_controller*`) not in progress. **Re-read every path in roadmap §6.6 on `main` first**; if ARCH G moved files, update this child's `allowed_paths` before stamping the snapshot |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Phases

| id | Title | Branch | Spec | exit_checklist |
|---|---|---|---|---|
| `W8` | Occurrence screen: user unit, skip with a reason, completed/skipped views, weight refresh; legacy weigh-in path removed | `cursor/weight-unify-w8-occurrence-9b2e` | §6.6, §7, tests FW-13…FW-16 | `flutter-screen-split` |
| `W9` | Observation slot on the care item view (`care_item/presentation/detail/`) + weight section | `cursor/weight-unify-w9-care-view-9b2e` | §6.1 (slot), §6.6, D-WM-013, test FW-17 | `flutter-screen-split` |
| `W10` | BDD and Playwright for the care side; programme close-out | `cursor/weight-unify-w10-e2e-9b2e` | §8.5 (W10 rows), §10.3 Exit | `bdd-journey` |

`allowed_paths` / `forbidden_paths` / `allowed_exceptions` per phase: see `weight-unify-care-9b2e.snapshot.json`.

**Exit (child):** roadmap §10.3 Exit.

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: W9
last_completed_phase: W8
halt_reason: null
next_action: "start phase W9: checkout cursor/weight-unify-w9-care-view-9b2e"
artifact_ref:
  branch: cursor/weight-unify-w8-occurrence-9b2e
  plan_path: .agents/plans/weight-unify-care-9b2e.md
  plan_commit: de382f1397d6d16469bbb8eb6e96bacba4b6ebed
  snapshot_path: .agents/plans/weight-unify-care-9b2e.snapshot.json
  snapshot_commit: de382f1397d6d16469bbb8eb6e96bacba4b6ebed
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
