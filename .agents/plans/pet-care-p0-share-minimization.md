---
title: Pet Care P0 — share preview minimization (F-03, F-04)
owner: Documentation Team
audience: agent
status: draft
last_updated: 2026-09-06
tags: [pet_care, security, execute-plan]
---

# Plan: pet-care-p0-share-minimization

## Goal

Close **F-03** and **F-04**: anonymous share preview exposes only scoped fields (name, species, breed, photo, age, owner first name); share links gain `expires_at` (default 7d, max 90d); expired and legacy unclaimed links return 410.

**Standing grant:** Pet Care hardening roadmap (user chat 2026-09-05).

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-06T04:35:00Z |
| **approved_until** | 2026-09-08T04:35:00Z |
| **approved_by** | standing grant — Pet Care hardening roadmap (user chat 2026-09-05) |
| **control_issue** | [#1000](https://github.com/KanopeeKa/AgathaCheck/issues/1000) |
| **autonomy** | `active` |

## Phases

### Phase 1 — Scoped share preview + link expiry

| Field | Value |
|-------|-------|
| **branch** | `cursor/pet-care-p0-share-minimization-75cb` |
| **exit_checklist** | `single-backend-route` |

**Exit criteria:**

- [ ] Preview excludes email, health, vet, insurance, chip
- [ ] `expires_at` enforced on preview + accept (410 when expired)
- [ ] Legacy unclaimed links revoked in migration
- [ ] Flutter share screen matches scoped preview
- [ ] `./scripts/pre-push-changed.sh` green

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/pet-care-p0-share-minimization-75cb"
artifact_ref:
  branch: cursor/pet-care-p0-share-minimization-75cb
  plan_path: .agents/plans/pet-care-p0-share-minimization.md
  plan_commit: 128d62a5ea815dad79ce5ddcaef9d4763bc57744
  snapshot_path: .agents/plans/pet-care-p0-share-minimization.snapshot.json
  snapshot_commit: 128d62a5ea815dad79ce5ddcaef9d4763bc57744
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/1001"]
merge_commits: {}
debt_issue_refs: []
```
