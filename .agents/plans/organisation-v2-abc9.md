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
current_phase: F0-F1
last_completed_phase: F0-F2
halt_reason: null
next_action: "start phase F0-F1: checkout cursor/org-v2-f0-docs-abc9"
artifact_ref:
  branch: cursor/org-v2-f0-perms-abc9
  plan_path: .agents/plans/organisation-v2-abc9.md
  plan_commit: 0ee634e32eee516bb85be58bffb5bfd556cf83db
  snapshot_path: .agents/plans/organisation-v2-abc9.snapshot.json
  snapshot_commit: 0ee634e32eee516bb85be58bffb5bfd556cf83db
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

Full phase list: `.agents/plans/organisation-v2-abc9.snapshot.json` (17 phases: F0-F1 … INT).
