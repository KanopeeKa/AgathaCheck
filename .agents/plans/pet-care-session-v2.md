---
title: Pet Care session v2 (F-05–F-07)
owner: Documentation Team
audience: agent
status: draft
last_updated: 2026-09-06
tags: [pet_care, security, execute-plan, auth]
---

# Plan: pet-care-session-v2

## Goal

Ship **session v2** for Pet Care mobile beta readiness: distinct access/refresh token types (F-05), server-side refresh sessions with rotation and logout invalidation (F-06), and secure web token storage (F-07). Cut over per product decision **E1** (no dual-mode).

**Standing grant:** Pet Care hardening roadmap (user chat 2026-09-05).

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-06T08:00:00Z |
| **approved_until** | 2026-09-08T08:00:00Z |
| **approved_by** | standing grant — Pet Care hardening roadmap (user chat 2026-09-05) |
| **control_issue** | [#1012](https://github.com/KanopeeKa/AgathaCheck/issues/1012) |
| **autonomy** | `active` |

## Phases

### Phase 1 — Backend refresh sessions + token typ claims (F-05, F-06)

| Field | Value |
|-------|-------|
| **branch** | `cursor/pet-care-session-v2-backend-75cb` |
| **exit_checklist** | `single-backend-route` |

**Exit criteria:**

- [ ] Access vs refresh JWTs carry distinct `typ`/purpose claims; cross-use rejected
- [ ] Server-side refresh session store with rotation + reuse detection
- [ ] Logout/password change revokes all sessions (E2/E4)
- [ ] Jest coverage for token type negatives + rotation/reuse

### Phase 2 — Flutter web secure storage cutover (F-07)

| Field | Value |
|-------|-------|
| **branch** | `cursor/pet-care-session-v2-flutter-75cb` |
| **exit_checklist** | `default` |

**Exit criteria:**

- [ ] Web: HttpOnly cookie refresh + in-memory access token
- [ ] Native path documented/unchanged or aligned
- [ ] Flutter tests updated

## Runtime state

```yaml
autonomy: active
current_phase: 2
last_completed_phase: 1
halt_reason: null
next_action: "continue phase 2 on branch cursor/pet-care-session-v2-flutter-75cb"
artifact_ref:
  branch: cursor/pet-care-session-v2-flutter-75cb
  plan_path: .agents/plans/pet-care-session-v2.md
  plan_commit: 4ee8cc6026ef1344fd7bda2f7cd01f1fd30eedcf
  snapshot_path: .agents/plans/pet-care-session-v2.snapshot.json
  snapshot_commit: 4ee8cc6026ef1344fd7bda2f7cd01f1fd30eedcf
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
