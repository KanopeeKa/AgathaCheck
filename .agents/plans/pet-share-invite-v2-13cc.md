# Share Pet — Invite model & consolidation (v2)

## Goal

Deliver email-based pet share invites and a unified `SharePetScreen` (single entry point from pet detail and bulk share), built in target backend/Flutter layering from day one. Phase 2 retrofits existing link/access routes into the same service/query structure without behavior change.

## Autonomy

| Field | Value |
|-------|-------|
| approved_at | 2026-09-17T21:15:00Z |
| approved_until | 2026-09-19T21:15:00Z |
| approved_by | standing grant — user chat 2026-09-17 execute-plan autonomous (v2 final spec) |
| control_issue | TBD |
| base_branch | cursor/pet-share-invite-integration-13cc |

## Phases

### Phase 1 — Invite feature + SharePetScreen (PR1)

Migration, shareInviteService, shareAccessService.listAccessForPets, notifications, email template, full SharePetScreen per viewer matrix, route additions, delete SharingController stub, tests and docs.

### Phase 2 — Retrofit link/access layering (PR2)

Extract sharing.js and petAccessRoutes.js into shareLinkService/shareAccessService + query modules; reconcile 403/404; existing tests pass unchanged.

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/pet-share-invite-pr1-13cc"
artifact_ref:
  branch: cursor/pet-share-invite-pr1-13cc
  plan_path: .agents/plans/pet-share-invite-v2-13cc.md
  plan_commit: bdeefc7a15046ead372f4aa1c6aa6ad4a17ef28d
  snapshot_path: .agents/plans/pet-share-invite-v2-13cc.snapshot.json
  snapshot_commit: bdeefc7a15046ead372f4aa1c6aa6ad4a17ef28d
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
