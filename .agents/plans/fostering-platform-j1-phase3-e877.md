# Plan — J1 Phase 3: Foster profiles and manual merge

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `fostering-platform-j1-phase3-e877` |
| **title** | J1 Phase 3 — foster_profiles table and manual foster merge |
| **author** | cloud-agent |
| **created** | 2026-07-25 |
| **base_branch** | `cursor/fostering-platform-j1-phase3-e877-integration` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Introduce the global `foster_profiles` table, link `org_foster_parents.foster_profile_id`, and deliver the G0 §9 manual foster merge flow (email match, survivor = registered profile, audit `foster_merge_completed`). Unblocks J2 identity/capacity and J3 `shelter_foster_relationship_id` handoff.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-07-25T12:00:00Z |
| **approved_until** | 2026-07-27T12:00:00Z |
| **control_issue** | (set in snapshot) |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous fostering-platform-j1-phase3-e877`

---

## Phase 1 — Backend foster_profiles + merge API

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/j1-foster-profiles-backend-e877` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
db/migrations/023_foster_profiles.sql
db/schema/migration-manifest.json
db/schema/canonical.sql
server/routes/organizations/fosterParentsRouter.js
server/lib/fosterProfiles.js
server/test/organizations/fosterParents.test.js
server/test/organizations/fosterProfiles.test.js
server/test/organizations/helpers.js
scripts/db/normalize-schema-dump.js
scripts/db/normalize-schema-dump.test.js
docs/fostering-platform/j1-foster-onboarding.md
docs/fostering-platform/roadmap-delivery-plan.md
.agents/plans/fostering-platform-j1-phase3-e877.*
```

**Scope:**

- Migration `023`: `foster_profiles` table; `foster_profile_id` on `org_foster_parents`
- Backfill profiles for existing `org_foster_parents` rows
- GET foster-parents includes `foster_profile_id`
- POST manual foster creates linked `foster_profiles` row
- `GET /:orgId/foster-parents/merge-suggestions?email=` duplicate hint
- `POST /:orgId/foster-parents/:id/merge` links manual record to target profile/user
- Audit `foster_merge_completed`
- Jest coverage

**Exit criteria:**

- [ ] Migration applies; manifest + canonical updated
- [ ] Every external foster parent has `foster_profile_id`
- [ ] Merge API updates relationship + profile `user_id` when target is registered
- [ ] Audit event on successful merge

---

## Phase 2 — Flutter merge flow

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/j1-foster-profiles-flutter-e877` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/organization/domain/entities/foster_parent.dart
flutter_app/lib/features/organization/data/datasources/organization_remote/**
flutter_app/lib/features/organization/data/datasources/organization_remote_datasource.dart
flutter_app/lib/features/organization/data/repositories/organization_repository_impl_foster.dart
flutter_app/lib/features/organization/domain/repositories/organization_repository.dart
flutter_app/lib/features/organization/presentation/providers/**
flutter_app/lib/features/organization/presentation/screens/manage_fosters/**
flutter_app/lib/features/organization/presentation/widgets/manage_fosters/**
flutter_app/lib/l10n/**
flutter_app/test/features/organization/**
docs/fostering-platform/j1-foster-onboarding.md
.agents/plans/fostering-platform-j1-phase3-e877.*
```

**Scope:**

- Entity: `fosterProfileId` on `FosterParent`
- Remote: merge suggestion + merge API calls
- Manage Fosters: merge action on external fosters when email matches registered user
- Success/error feedback; list refresh
- Unit/widget tests; l10n EN/FR

**Exit criteria:**

- [ ] Staff can merge manual foster into registered account from Manage Fosters
- [ ] Merged record shows linked profile state
- [ ] Tests pass

---

## Runtime state

```yaml
autonomy: completed
current_phase: null
last_completed_phase: 2
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: cursor/execute-plan-roadmap-chaining-58d8
  plan_path: .agents/plans/fostering-platform-j1-phase3-e877.md
  plan_commit: ff54f3c2b17b0e668fe4322209c8cce09f7739a8
  snapshot_path: .agents/plans/fostering-platform-j1-phase3-e877.snapshot.json
  snapshot_commit: ff54f3c2b17b0e668fe4322209c8cce09f7739a8
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
