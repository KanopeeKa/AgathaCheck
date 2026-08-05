# Example plan — widget extraction (documentation only)

> **plan_id:** `example-plan`  
> This file is a **sample** for schema validation. Do not invoke `/execute-plan example-plan` in production.

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `example-plan` |
| **title** | Extract FosterCard widgets (example) |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Demonstrate a two-phase Flutter screen split with schema-compliant snapshot and exit checklists. Not intended for execution.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-07-16T21:00:00Z` |
| **approved_until** | `2026-07-18T21:00:00Z` |
| **control_issue** | `0` (placeholder) |
| **content_hash** | see `_example.snapshot.json` |
| **autonomy** | `halted` |

## Phases

### Phase 1 — Extract FosterCard widgets

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/example-foster-widgets-aec1` |
| **exit_checklist** | `flutter-screen-split` |
| **merge_mode** | `auto` |

**allowed_paths:** `flutter_app/lib/features/foster/presentation/**`, `flutter_app/test/features/foster/**`

**allowed_exceptions:** `tests`, `docs`, `file-split`

### Phase 2 — Wire tests and docs

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/example-foster-docs-aec1` |
| **exit_checklist** | `default` |
| **merge_mode** | `auto` |

## Runtime state

```yaml
autonomy: halted
current_phase: null
last_completed_phase: null
halt_reason: "documentation example — not for execution"
next_action: null
artifact_ref:
  branch: null
  plan_path: .agents/plans/example-plan.md
  plan_commit: null
  snapshot_path: .agents/plans/example-plan.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
