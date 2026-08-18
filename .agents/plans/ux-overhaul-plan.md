# UX Overhaul Plan

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `ux-overhaul-plan` |
| **title** | Navigation & Onboarding UX Overhaul |
| **author** | Cloud Agent |
| **created** | 2026-08-18 |
| **base_branch** | `cursor/ux-overhaul-integration-13e3` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Fix the confusion between "Guardian" and "Organisation" as top-level identities, simplify onboarding, and define what screen users land on after login. The app's content model already treats guardian/org as unified, but its navigation and onboarding treat them as a binary identity. This plan unifies the daily care view under "My Pets" and makes shelter administration an occasional, clearly-scoped destination.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-08-18T12:54:00Z |
| **approved_until** | 2026-08-20T12:54:00Z |
| **control_issue** | 1 |
| **content_hash** | pending |
| **autonomy** | `active` |

## Phases

### Phase 1 — Routing, Navigation & Form Polish

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/ux-overhaul-phase1-13e3` |
| **spawn_allowed** | `true` |
| **exit_checklist** | `default` |

**allowed_paths:**
```
flutter_app/lib/core/router/**
flutter_app/lib/features/experience/presentation/screens/**
flutter_app/lib/features/health_tracking/presentation/**
flutter_app/lib/features/pet_profile/presentation/**
flutter_app/lib/features/organization/presentation/**
flutter_app/lib/l10n/**
```

**forbidden_paths:**
```
server/**
.github/workflows/**
```

**allowed_exceptions:**
```
tests
docs
file-split
spawn-integration
```

**Scope:**
- Update global UI strings: `Guardian` ➔ `My Pets`, `Organisation` ➔ `Shelters`.
- Implement Deterministic Landing Rules in `app_router.dart` and `experience_resolve_screen.dart`.
- Ensure global notification bell deep-links into Shelter views.
- Remove redundant validation Snackbars from form screens.
- Refactor `HealthEntryRemindField` to a Dropdown/ChoiceChips.
- Fix `confirmDeletePet` dialog to display pet name.
- Remove empty string hack in `OrganizationFormScreen`.

**Exit criteria:**
- [ ] Navigation labels updated.
- [ ] Deterministic landing works correctly for all 3 user states.
- [ ] Form validation uses inline red borders instead of Snackbars.
- [ ] Reminders field is easier to use.
- [ ] Delete pet dialog shows pet name.

---

### Phase 2 — Onboarding & Empty States

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/ux-overhaul-phase2-13e3` |
| **spawn_allowed** | `true` |
| **exit_checklist** | `default` |

**allowed_paths:**
```
flutter_app/lib/features/auth/presentation/**
flutter_app/lib/features/experience/presentation/**
flutter_app/lib/features/organization/presentation/**
flutter_app/lib/l10n/**
```

**forbidden_paths:**
```
server/**
.github/workflows/**
```

**allowed_exceptions:**
```
tests
docs
file-split
spawn-integration
```

**Scope:**
- Replace `ExperienceChooserScreen` with an Action-Oriented FTUE screen (3 choices).
- Update auth logic for invite link bypass.
- Redesign "My Pets" empty state with cross-linking to Shelters.
- Ensure Shelter Settings are accessible inside the Shelter dashboard.

**Exit criteria:**
- [ ] FTUE screen shows 3 clear actions.
- [ ] Invite links bypass FTUE.
- [ ] Empty state cross-links to Shelters for pure admins.
- [ ] Shelter Settings accessible from Shelter dashboard.

---

### Phase 3 — Architecture Cleanup

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/ux-overhaul-phase3-13e3` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:**
```
flutter_app/lib/features/experience/domain/**
flutter_app/lib/features/experience/data/**
flutter_app/lib/features/experience/presentation/**
flutter_app/lib/core/router/**
```

**forbidden_paths:**
```
server/**
.github/workflows/**
```

**allowed_exceptions:**
```
tests
docs
file-split
```

**Scope:**
- Strip out legacy `AppExperience` state management.
- Verify "My Pets" architecture is clean.

**Exit criteria:**
- [ ] `AppExperience` state removed.
- [ ] App is fully context-driven.

## Spawn phase

| Field | Value |
|-------|-------|
| **spawn_allowed** | `true` |
| **integration_branch** | `cursor/ux-overhaul-integration-13e3` |
| **ownership_ref** | `docs/refactoring-log.md#ux-overhaul` |

## Runtime state

```yaml
autonomy: active
current_phase: 2
last_completed_phase: 1
halt_reason: null
next_action: "continue phase 2 on branch cursor/ux-overhaul-phase2-13e3"
artifact_ref:
  branch: cursor/ux-overhaul-phase1-13e3
  plan_path: .agents/plans/ux-overhaul-plan.md
  plan_commit: 28f59e0e5d8f0d70a489fef8c595358e7c41ba42
  snapshot_path: .agents/plans/ux-overhaul-plan.snapshot.json
  snapshot_commit: 28f59e0e5d8f0d70a489fef8c595358e7c41ba42
open_prs: ["pending"]
merge_commits: {}
debt_issue_refs: []
```
