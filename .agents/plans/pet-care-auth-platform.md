---
title: Pet Care auth platform — central auth + capability skeleton (F-08)
owner: Documentation Team
audience: agent
status: draft
last_updated: 2026-09-06
tags: [pet_care, security, execute-plan]
---

# Plan: pet-care-auth-platform

## Goal

Establish shared Pet Care auth foundations: **F-08** central `requireAuth` middleware (replace duplicated `extractUserId`), capability policy skeleton with discovery §Capability seeds, and consistent error/validation patterns for downstream rollout (`pet-care-capability-auth-rollout`).

**Standing grant:** Pet Care hardening roadmap (user chat 2026-09-05).

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-06T06:00:00Z |
| **approved_until** | 2026-09-08T06:00:00Z |
| **approved_by** | standing grant — Pet Care hardening roadmap (user chat 2026-09-05) |
| **control_issue** | [#1005](https://github.com/KanopeeKa/AgathaCheck/issues/1005) |
| **autonomy** | `active` |

## Phases

### Phase 1 — Central auth middleware + capability policy skeleton

| Field | Value |
|-------|-------|
| **branch** | `cursor/pet-care-auth-platform-75cb` |
| **exit_checklist** | `single-backend-route` |

**Exit criteria:**

- [ ] `server/lib/requireAuth.js` (or `server/middleware/requireAuth.js`) — typed principal, 401 on missing/invalid token
- [ ] `server/lib/petCapabilityPolicy.js` — capability constants + `hasPetCapability(pool, userId, petId, capability)` skeleton
- [ ] Migrate Pet Care routes off local `extractUserId` duplicates (sharing, pets, health, weight, vets, notifications)
- [ ] Jest coverage for auth middleware + policy skeleton
- [ ] `./scripts/pre-push-changed.sh` green

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/pet-care-auth-platform-75cb"
artifact_ref:
  branch: cursor/pet-care-auth-platform-75cb
  plan_path: .agents/plans/pet-care-auth-platform.md
  plan_commit: 6a47948edffdbfa989a5ee34c396dd1f9113de99
  snapshot_path: .agents/plans/pet-care-auth-platform.snapshot.json
  snapshot_commit: 6a47948edffdbfa989a5ee34c396dd1f9113de99
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/1006"]
merge_commits: {}
debt_issue_refs: []
```
