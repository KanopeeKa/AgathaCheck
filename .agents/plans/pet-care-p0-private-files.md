---
title: Pet Care P0 — private health files (F-01)
owner: Documentation Team
audience: agent
status: draft
last_updated: 2026-09-05
tags: [pet_care, security, execute-plan]
---

# Plan: pet-care-p0-private-files

## Goal

Close **F-01**: health documents and entry photos are no longer publicly servable via `express.static` or `/api/uploads`. Bytes are streamed only through an authenticated `/api/health-files/:id` route after pet-access checks. Legacy files are migrated off public paths.

**Standing grant:** Pet Care hardening roadmap authorized in user chat 2026-09-05 (discovery #993).

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-05T23:55:00Z |
| **approved_until** | 2026-09-07T23:55:00Z |
| **approved_by** | standing grant — Pet Care hardening roadmap (user chat 2026-09-05) |
| **control_issue** | TBD |
| **autonomy** | `active` |

## Router annotations

```text
router_risk: R2 (security — private health data)
protocols: [security, authorization, private-files, api-contract, validation, testing]
verification: [server Jest health + publicUploads, flutter analyze, pre-push-changed.sh]
phase_fit: in-scope
```

## Phases

### Phase 1 — Private health file serving

| Field | Value |
|-------|-------|
| **branch** | `cursor/pet-care-p0-private-files-75cb` |
| **exit_checklist** | `single-backend-route` |

**Deliverables:**

- Private storage + authenticated `GET /api/health-files/:id`
- Block public access to `health_documents` / `health_photos`
- Migration `050` moves legacy files and updates URL columns
- Flutter authenticated image fetch for health attachments
- Tests: anonymous 404, authorized stream, public URL blocked

**Exit criteria:**

- [ ] Anonymous GET `/uploads/health_documents/*` returns 404
- [ ] Authorized user can stream own pet health file bytes
- [ ] Unrelated user receives 404 on health-files API
- [ ] Flutter health document widgets load with auth headers
- [ ] `./scripts/pre-push-changed.sh` green

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/pet-care-p0-private-files-75cb"
artifact_ref:
  branch: cursor/pet-care-p0-private-files-75cb
  plan_path: .agents/plans/pet-care-p0-private-files.md
  plan_commit: 18a1bc7510d46fed1b29383c8393b17b84571eeb
  snapshot_path: .agents/plans/pet-care-p0-private-files.snapshot.json
  snapshot_commit: 18a1bc7510d46fed1b29383c8393b17b84571eeb
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
