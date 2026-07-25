# Plan — J1 Phase 4: Compliance, retention, and privacy copy

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `fostering-platform-j1-phase4-e877` |
| **title** | J1 Phase 4 — compliance, retention, privacy copy |
| **author** | cloud-agent |
| **created** | 2026-07-25 |
| **base_branch** | `cursor/fostering-platform-j1-phase4-e877-integration` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Deliver G0 §11 retention categories and opt-out on shelter–foster relationships, refresh Art. 14 privacy notice copy (EN/FR), and update the foster-directory DPIA. Unblocks prod expansion of manual foster flows and J2 outreach guards.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-07-25T12:30:00Z |
| **approved_until** | 2026-07-27T12:30:00Z |
| **control_issue** | (set in snapshot) |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous fostering-platform-j1-phase4-e877`

---

## Phase 1 — Backend compliance fields + API

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/j1-foster-compliance-backend-e877` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
db/migrations/024_org_foster_parents_compliance.sql
db/schema/migration-manifest.json
db/schema/canonical.sql
server/routes/organizations/fosterParentsRouter.js
server/lib/fosterCompliance.js
server/lib/email/i18n.js
server/test/organizations/fosterParents.test.js
server/test/organizations/fosterCompliance.test.js
server/test/organizations/helpers.js
regulatory/internal/dpia-foster-directory.md
docs/fostering-platform/j1-foster-onboarding.md
docs/fostering-platform/roadmap-delivery-plan.md
.agents/plans/fostering-platform-j1-phase4-e877.*
```

**Scope:**

- Migration `024`: `opt_out_at`, `retention_category` on `org_foster_parents` with G0-bounded CHECK
- Backfill `retention_category` from `approval_state` / `creation_source`
- GET foster-parents exposes `opt_out_at`, `retention_category`
- `PATCH /:orgId/foster-parents/:id/opt-out` sets/clears outreach opt-out
- `PATCH /:orgId/foster-parents/:id/retention` updates category within allowed set
- Audit events on opt-out and retention changes
- Refresh `externalFosterNotice` email copy (EN/FR) per Art. 14
- DPIA checklist items for J1 Ph4

**Exit criteria:**

- [ ] Migration applies; manifest + canonical updated
- [ ] External fosters expose compliance fields
- [ ] Opt-out and retention PATCH routes tested
- [ ] Email + DPIA docs updated

---

## Phase 2 — Flutter compliance UI

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/j1-foster-compliance-flutter-e877` |
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
.agents/plans/fostering-platform-j1-phase4-e877.*
```

**Scope:**

- Entity: `optOutAt`, `retentionCategory` on `FosterParent`
- Remote/repository: opt-out + retention PATCH calls
- Manage Fosters: opt-out toggle and retention category chip for external fosters
- Updated lawful-basis / privacy helper copy in add-manual dialog
- EN/FR l10n; widget tests

**Exit criteria:**

- [ ] Staff can record outreach opt-out from Manage Fosters
- [ ] Retention category visible on external foster cards
- [ ] Tests pass

---

## Runtime state

```yaml
autonomy: active
current_phase: 2
last_completed_phase: 1
halt_reason: null
next_action: "continue phase 2 on branch cursor/j1-foster-compliance-flutter-e877"
artifact_ref:
  branch: cursor/j1-foster-compliance-flutter-e877
  plan_path: .agents/plans/fostering-platform-j1-phase4-e877.md
  plan_commit: 7b40a0c8e61af1e634d47d11d4fbb0b640e7f383
  snapshot_path: .agents/plans/fostering-platform-j1-phase4-e877.snapshot.json
  snapshot_commit: 7b40a0c8e61af1e634d47d11d4fbb0b640e7f383
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
