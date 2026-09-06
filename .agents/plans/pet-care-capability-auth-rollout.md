---
title: Pet Care capability auth rollout (F-02)
owner: Documentation Team
audience: agent
status: draft
last_updated: 2026-09-06
tags: [pet_care, security, execute-plan]
---

# Plan: pet-care-capability-auth-rollout

## Goal

Implement **F-02** fine-grained Pet Care authorization: differentiate read vs manage capabilities per discovery §Capability seeds and product decisions (org viewers read-only; collaborators/fosters may edit; owner-only lifecycle). Wire route handlers to `hasPetCapability` and add negative authorization matrix tests.

**Standing grant:** Pet Care hardening roadmap (user chat 2026-09-05).

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-06T06:35:00Z |
| **approved_until** | 2026-09-08T06:35:00Z |
| **approved_by** | standing grant — Pet Care hardening roadmap (user chat 2026-09-05) |
| **control_issue** | [#1008](https://github.com/KanopeeKa/AgathaCheck/issues/1008) |
| **autonomy** | `active` |

## Phases

### Phase 1 — Capability policy rollout + route wiring (F-02)

| Field | Value |
|-------|-------|
| **branch** | `cursor/pet-care-capability-auth-rollout-75cb` |
| **exit_checklist** | `single-backend-route` |

**Exit criteria:**

- [ ] `userCanManagePet` excludes org-viewer-only access; collaborators/fosters retain manage
- [ ] `hasPetCapability` implements discovery capability seeds per actor matrix
- [ ] Pet Care routes use `hasPetCapability` for read vs write gates
- [ ] Negative authorization matrix tests (org viewer, collaborator, owner, stranger)
- [ ] `./scripts/pre-push-changed.sh` green

## Runtime state

```yaml
autonomy: completed
current_phase: null
last_completed_phase: 1
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: main
  plan_path: .agents/plans/pet-care-capability-auth-rollout.md
  plan_commit: f298343855e184b103d181fdfb199ad91c86078c
  snapshot_path: .agents/plans/pet-care-capability-auth-rollout.snapshot.json
  snapshot_commit: f298343855e184b103d181fdfb199ad91c86078c
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
