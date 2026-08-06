# Organisation v4 — people, permissions & foster

**plan_id:** `organisation-v4-people-perms`  
**Control issue:** #621  
**Delivery spec:** [`organisation-people-permissions-v4-delivery-plan.md`](../../docs/experience-program/organisation-people-permissions-v4-delivery-plan.md)  
**Integration branch:** `cursor/organisation-v4-people-perms-integration-63a7`

## Goal

Implement unified People directory, retire foster wire role (badge instead), staged permissions
editor, org tier defaults, foster invites, and onboarding timeline per D-v4-* decisions.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-08-06T17:20:00Z |
| **approved_until** | 2026-08-08T17:20:00Z |
| **approved_by** | User chat: /execute-plan full spec, no permission between phases |
| **autonomy** | active |

## Runtime state

```yaml
autonomy: active
current_phase: A
last_completed_phase: null
halt_reason: null
next_action: "continue phase A on branch cursor/org-v4-a-create-edit-form-63a7"
artifact_ref:
  branch: cursor/org-v4-a-create-edit-form-63a7
  plan_path: .agents/plans/organisation-v4-people-perms.md
  plan_commit: 49f6d3e68d1f4c0824f1568ffe8627d4766a5bd8
  snapshot_path: .agents/plans/organisation-v4-people-perms.snapshot.json
  snapshot_commit: 49f6d3e68d1f4c0824f1568ffe8627d4766a5bd8
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

See `.agents/plans/organisation-v4-people-perms.snapshot.json` for allowed_paths and status.

| ID | Title | Branch |
|----|-------|--------|
| A | Create/Edit org template parity | `cursor/org-v4-a-create-edit-form-63a7` |
| B | People screen + admin contacts retirement | `cursor/org-v4-b-people-screen-63a7` |
| C | Wire role retirement + foster badge | `cursor/org-v4-c-role-badge-63a7` |
| D | People multi-select + bulk actions | `cursor/org-v4-d-people-bulk-63a7` |
| E | Staged permissions editor | `cursor/org-v4-e-permissions-staged-63a7` |
| F | Org default permission sets | `cursor/org-v4-f-org-bundle-defaults-63a7` |
| G | Foster invite + email templates | `cursor/org-v4-g-foster-invite-63a7` |
| H | Foster onboarding timeline | `cursor/org-v4-h-foster-timeline-63a7` |

Final PR: integration → `main` via **/babysit-uat**.
