# Plan — J1 Phase 2: Foster approval state

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `fostering-platform-j1-phase2-e877` |
| **title** | J1 Phase 2 — approval_state migration, API, and Manage Fosters filters |
| **author** | cloud-agent |
| **created** | 2026-07-25 |
| **base_branch** | `cursor/fostering-platform-j1-phase2-e877-integration` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Deliver J1 Phase 2: `approval_state` and `creation_source` on `org_foster_parents`, foster-parents API exposure and PATCH approval transitions with G0 audit events, and Flutter Manage Fosters approval filters/actions wired to the backend.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-07-25T00:05:00Z |
| **approved_until** | 2026-07-27T00:05:00Z |
| **control_issue** | (set in snapshot) |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous fostering-platform-j1-phase2-e877`

---

## Phase 1 — Backend approval state

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/j1-approval-state-backend-e877` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
db/migrations/022_org_foster_parents_approval_state.sql
server/routes/organizations/fosterParentsRouter.js
server/test/organizations/fosterParents.test.js
server/test/organizations/helpers.js
docs/fostering-platform/j1-foster-onboarding.md
.agents/plans/fostering-platform-j1-phase2-e877.*
```

**forbidden_paths:**

```
flutter_app/**
.github/workflows/**
```

**Scope:**

- Migration: `approval_state`, `creation_source` on `org_foster_parents` (legacy → `approved`)
- GET foster-parents: include `approval_state` (members virtual `approved`)
- POST: `under_review` + `manual_shelter_entry`; audit `manual_foster_record_created`
- PATCH `/:id/approval`: approve / decline / archive with audit events
- Jest coverage for new routes and fields

**Exit criteria:**

- [ ] Migration 022 applies cleanly
- [ ] API returns `approval_state` on all foster-parent rows
- [ ] Approval PATCH transitions work for external fosters only
- [ ] Audit events emitted per G0 §8

---

## Phase 2 — Flutter approval UI

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/j1-approval-state-flutter-e877` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/organization/domain/entities/foster_parent.dart
flutter_app/lib/features/organization/data/datasources/organization_remote/organization_foster_parents_remote.dart
flutter_app/lib/features/organization/data/datasources/organization_remote_datasource.dart
flutter_app/lib/features/organization/presentation/providers/manage_fosters_providers.dart
flutter_app/lib/features/organization/presentation/providers/organization_providers.dart
flutter_app/lib/features/organization/presentation/screens/manage_fosters/**
flutter_app/lib/features/organization/presentation/widgets/manage_fosters/**
flutter_app/lib/l10n/**
flutter_app/test/features/organization/**
docs/fostering-platform/j1-foster-onboarding.md
.agents/plans/fostering-platform-j1-phase2-e877.*
```

**forbidden_paths:**

```
server/**
db/**
.github/workflows/**
```

**Scope:**

- `FosterParent` entity: `approvalState`, `creationSource`
- Remote datasource: `updateFosterApproval`
- Enable approval filter chips; filter list by `approval_state`
- External foster cards: approve / decline / archive actions
- Approval state chip on summary cards
- Unit/widget tests; l10n EN/FR

**Exit criteria:**

- [ ] Approval filters functional (under_review, approved, archived)
- [ ] Approve/decline/archive actions call API and refresh list
- [ ] Member fosters show virtual approved; actions hidden
- [ ] Tests pass

---

## Runtime state

```yaml
autonomy: active
current_phase: "1"
last_completed_phase: null
halt_reason: null
next_action: null
```
