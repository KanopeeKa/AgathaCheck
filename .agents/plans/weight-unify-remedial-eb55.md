# Weight programme remedial — post-landing review fixes

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `weight-unify-remedial-eb55` |
| **title** | Weight unify remedial: establishment timing, save mode, UX, hooks, docs |
| **base_branch** | `cursor/weight-unify-remedial-integration-eb55` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Address the post-programme review on `main`: fix establishment evaluation ordering, Flutter save create/update robustness, Record weight counts-as timeout UX, explicit weight undo hook registration, lib/routes layering for weight completion helpers, lightweight weight analytics, and programme bookkeeping snapshots/docs.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_by** | User chat 2026-10-05: "/execute-plan … fix all … without asking" |
| **control_issue** | (set in snapshot) |

## Phases

| id | Title | Branch |
|----|-------|--------|
| R1 | Server: establishment after completion, F-23 assertion, hook bootstrap test | `cursor/weight-remedial-establish-eb55` |
| R2 | Flutter: explicit save mode, counts-as timeout/copy, weight analytics | `cursor/weight-remedial-flutter-eb55` |
| R3 | Server: move weight completion helpers to lib, drop allowlist | `cursor/weight-remedial-layer-eb55` |
| R4 | Docs: roadmap snapshot, parallel-programmes, hub PR URL | `cursor/weight-remedial-docs-eb55` |

## Runtime state

```yaml
autonomy: active
current_phase: R1
next_action: implement R1
```
