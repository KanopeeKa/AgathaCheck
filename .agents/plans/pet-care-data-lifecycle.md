---
title: Pet Care data lifecycle (F-09–F-12)
owner: Documentation Team
audience: agent
status: draft
last_updated: 2026-09-06
tags: [pet_care, security, execute-plan, lifecycle]
---

# Plan: pet-care-data-lifecycle

## Goal

Implement real pet data deletion, passed-away collaborator notifications, account-deletion file purge, and Flutter repository wiring for lifecycle endpoints (F-09–F-12). Depends on private-files storage abstraction from `pet-care-p0-private-files`.

**Standing grant:** Pet Care hardening roadmap (user chat 2026-09-05).

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-06T10:35:00Z |
| **approved_until** | 2026-09-08T10:35:00Z |
| **approved_by** | standing grant — Pet Care hardening roadmap (user chat 2026-09-05) |
| **control_issue** | TBD |
| **autonomy** | `active` |

## Phases

### Phase 1 — Backend lifecycle + account file purge (F-09, F-10, F-12)

| Field | Value |
|-------|-------|
| **branch** | `cursor/pet-care-data-lifecycle-backend-75cb` |
| **exit_checklist** | `single-backend-route` |

**Exit criteria:**

- [ ] `DELETE /api/pets/:id/data` removes pet-related rows and health files from disk
- [ ] `POST /api/pets/:id/passed-away` notifies collaborators; returns `notified_count`
- [ ] `DELETE /api/auth/me` purges owned-pet health files before user row delete
- [ ] Jest integration tests prove data/files removed

### Phase 2 — Flutter lifecycle repository cutover (F-11)

| Field | Value |
|-------|-------|
| **branch** | `cursor/pet-care-data-lifecycle-flutter-75cb` |
| **exit_checklist** | `default` |

**Exit criteria:**

- [ ] `deletePet` / `markPassedAway` route through repository/datasource (no raw URLs in providers)
- [ ] Widget/unit tests updated

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/pet-care-data-lifecycle-backend-75cb"
artifact_ref:
  branch: cursor/pet-care-data-lifecycle-backend-75cb
  plan_path: .agents/plans/pet-care-data-lifecycle.md
  plan_commit: 82397e4702cdd2a0abc0a17679e338c1ee0110f9
  snapshot_path: .agents/plans/pet-care-data-lifecycle.snapshot.json
  snapshot_commit: 82397e4702cdd2a0abc0a17679e338c1ee0110f9
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
