# Plan — Organisation v2

| Field | Value |
|-------|-------|
| **plan_id** | `organisation-v2-abc9` |
| **title** | Organisation v2 — profile composer, view permissions, activity log |
| **base_branch** | `cursor/organisation-v2-integration-abc9` |
| **default_merge_mode** | `auto` |
| **control_issue** | #537 |

## Goal

Rebuild the Organisation area around a single organisation profile (pet-profile-style stacked flow), with public/member tiers, formal `view_*` permissions, product activity log for last-activity sorting, and full BDD/TDD coverage. See `docs/experience-program/organisation-v2-delivery-plan.md`.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-08-02T22:40:00Z |
| **approved_until** | 2026-08-04T22:40:00Z |
| **approved_by** | user chat 2026-08-02 (full /execute-plan, Option B associate pet view) |
| **autonomy** | `active` |

## Runtime state

```yaml
autonomy: active
current_phase: 2a
last_completed_phase: F0-F2
halt_reason: null
next_action: "continue phase 2a on branch cursor/org-v2-2a-profile-abc9"
artifact_ref:
  branch: cursor/organisation-v2-integration-abc9
  plan_path: .agents/plans/organisation-v2-abc9.md
  plan_commit: 48df28b94b69efb196b35b7c7e098f8cdc22f0be
  snapshot_path: .agents/plans/organisation-v2-abc9.snapshot.json
  snapshot_commit: 48df28b94b69efb196b35b7c7e098f8cdc22f0be
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

Full phase list: `.agents/plans/organisation-v2-abc9.snapshot.json` (17 phases: F0-F1 … INT).
