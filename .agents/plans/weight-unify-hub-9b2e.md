# WEIGHT child B — Flutter: unit preference, one weight cache, read-only pet weight, the weight screen and Record weight sheet

> **Child of** [`weight-monitoring-unify-9b2e`](./weight-monitoring-unify-9b2e.md). **All rules, contracts, tests and copy are in the roadmap.** This file holds the phase table and runtime state only. Read roadmap §0 before starting.

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `weight-unify-hub-9b2e` |
| **parent** | `weight-monitoring-unify-9b2e` (roadmap) |
| **base_branch** | `cursor/weight-unify-hub-integration-9b2e` (create from a fresh `origin/main` after child A has landed) |
| **control issue** | own issue, created at bootstrap under the roadmap's standing grant (roadmap §11.1); placeholder `999999` until then |
| **landing** | integration → `main` PR, `/babysit-uat` until pre-UAT green, then the landing broadcast (roadmap §10.4) |
| **entry gate** | roadmap §10.2: child A landed; ARCH G phase 1 (`pet_profile` providers/data/domain, `pet_detail_screen.dart`) not in progress |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Phases

| id | Title | Branch | Spec | exit_checklist |
|---|---|---|---|---|
| `W5` | Flutter foundations: core unit + preference + sync hooks, one weight cache, read-only pet weight (Flutter only) | `cursor/weight-unify-w5-foundations-9b2e` | §6.1, §6.2, §6.7, tests FW-1…FW-5 | `flutter-screen-split` |
| `W6` | Weight screen, Record weight sheet with "Counts as" (Save waits for the check), delete confirmation | `cursor/weight-unify-w6-hub-9b2e` | §6.3–§6.5, §7, tests FW-6…FW-12, FW-18 | `flutter-screen-split` |
| `W7` | BDD and Playwright for the weight screen and the read-only profile weight | `cursor/weight-unify-w7-e2e-9b2e` | §8.5 (W7 rows) | `bdd-journey` |

**W5 compatibility shim** (roadmap §6.2): keep `WeightUnit` re-exported from `weight_providers.dart` and a `@Deprecated` `weightUnitProvider` family returning the user preference, because the legacy `health_tracking` weigh-in path still reads them until child C.

`allowed_paths` / `forbidden_paths` / `allowed_exceptions` per phase: see `weight-unify-hub-9b2e.snapshot.json`.

**Exit (child):** roadmap §10.2 Exit.

## Runtime state (agent-updated)

```yaml
autonomy: halted
current_phase: null
last_completed_phase: null
halt_reason: "draft — waits for child A landing"
next_action: "after child A lands: check entry gate §10.2, create cursor/weight-unify-hub-integration-9b2e from origin/main, init-control-issue weight-unify-hub-9b2e, start W5"
artifact_ref:
  branch: null
  plan_path: .agents/plans/weight-unify-hub-9b2e.md
  plan_commit: null
  snapshot_path: .agents/plans/weight-unify-hub-9b2e.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
