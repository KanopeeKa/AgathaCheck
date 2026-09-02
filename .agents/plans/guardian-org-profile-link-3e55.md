---
title: Guardian org profile link
owner: Agent
audience: agent
status: active
last_updated: 2026-09-01
tags: [guardian, navigation, organisation]
---

# Guardian org profile link

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `guardian-org-profile-link-3e55` |
| **title** | Pet Care dashboard shelter link → org presentation |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Shelter rows on the My Pets dashboard fostering section should open the organisation presentation (`/o/orgs/:id`), and back should return to the calling guardian route.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-01T08:24:00Z |
| **approved_until** | 2026-09-03T08:24:00Z |
| **control_issue** | (session bootstrap) |
| **autonomy** | `active` |

**Grant:** user chat 2026-09-01 — implement analysis fix + origin-aware back via `/execute-plan`.

## Phases

### Phase 1 — Shelter link and origin-aware back

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/guardian-org-profile-link-3e55` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
flutter_app/lib/features/experience/presentation/widgets/guardian_fostering_section.dart
flutter_app/lib/features/organization/presentation/screens/organisation_profile_screen.dart
flutter_app/lib/features/organization/presentation/utils/org_profile_return.dart
flutter_app/lib/core/router/organization_routes.dart
flutter_app/test/features/experience/presentation/widgets/guardian_fostering_section_test.dart
flutter_app/test/features/organization/presentation/screens/organisation_profile_screen_test.dart
flutter_app/test/features/organization/presentation/utils/org_profile_return_test.dart
.agents/plans/guardian-org-profile-link-3e55.*
```

**Exit criteria:**

- [x] Shelter row opens `/o/orgs/:id` with `returnTo` from guardian dashboard
- [x] Org profile back pops stack or uses `returnTo`
- [x] Widget tests cover navigation and back

## Runtime state

| Phase | Status | PR |
|-------|--------|-----|
| 1 | in_progress | — |
