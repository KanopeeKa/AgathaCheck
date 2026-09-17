---
title: Personal pet list role split
owner: Agent
audience: agent
status: active
last_updated: 2026-09-17
tags: [pet-care, pet-profile, sharing]
---

# Personal pet list role split (`personal-pet-list-role-split-6d00`)

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `personal-pet-list-role-split-6d00` |
| **title** | Distinguish co-parent from carer pets on dashboard and /pc/pets |
| **author** | Cloud agent (user chat 2026-09-17, spec v3) |
| **created** | 2026-09-17 |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Split personal pet display buckets by `accessRole`: co-parent pets appear under My Pets; carer pets appear in a dedicated section. Keep bulk-share eligibility unchanged via a separate shareable-pets helper. Parent grouping by pet owner is deferred.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-17T23:05:00Z |
| **approved_until** | 2026-09-19T23:05:00Z |
| **approved_by** | user chat 2026-09-17 `/execute-plan autonomously` |
| **control_issue** | #1233 |
| **autonomy** | `active` |

## Phases

### Phase 1 — Role split helpers and UI

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/personal-pet-list-role-split-6d00` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_dashboard_helpers.dart
flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_my_pets_section.dart
flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_bulk_share_select_screen.dart
flutter_app/lib/features/pet_profile/presentation/widgets/pet_list/guardian_embedded_pets_list.dart
flutter_app/lib/l10n/**
flutter_app/test/features/experience/presentation/screens/pet_care/**
flutter_app/test/features/pet_profile/presentation/widgets/pet_list/guardian_embedded_pets_list_test.dart
.agents/plans/personal-pet-list-role-split-6d00.md
.agents/plans/personal-pet-list-role-split-6d00.snapshot.json
```

**Scope:**

- `petCareDashboardPersonalPets` — owned + co-parent (+ foster unchanged)
- `petCareDashboardShareablePets` — `!isShared` only for bulk share
- `petCareDashboardCarerPets` — replaces shared bucket
- `petCareTodayPetRelationship` — co-parent → owned
- UI title/key updates; dashboard card wrapper rules
- Unit and widget tests

**Exit criteria:**

- [ ] Co-parent in My Pets; carer in carer section on `/pc/pets` and dashboard
- [ ] Co-parent excluded from bulk-share picker
- [ ] Tests green via `./scripts/pre-push-changed.sh`

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/personal-pet-list-role-split-6d00"
artifact_ref:
  branch: cursor/personal-pet-list-role-split-6d00
  plan_path: .agents/plans/personal-pet-list-role-split-6d00.md
  plan_commit: 5f84781bb008338d92b64288686dbfed7b8d8322
  snapshot_path: .agents/plans/personal-pet-list-role-split-6d00.snapshot.json
  snapshot_commit: 5f84781bb008338d92b64288686dbfed7b8d8322
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/1234"]
merge_commits: {}
debt_issue_refs: []
```
