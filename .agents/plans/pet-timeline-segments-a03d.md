# Pet timeline custody & gaps — execute-plan

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `pet-timeline-segments-a03d` |
| **title** | Enable custody and gap segments on pet timeline |
| **author** | cloud-agent |
| **created** | 2026-08-02 |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Enable custody transfer segments and gap placeholders on the pet timeline (phase 2 of timeline work), including gap fill actions that pre-populate dates from the gap range.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-08-02T18:05:00Z |
| **approved_until** | 2026-08-04T18:05:00Z |
| **approved_by** | user chat standing grant (execute-plan continuation) |
| **autonomy** | `active` |

## Phases

### Phase 1 — Custody and gap segments

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/pet-timeline-segments-a03d` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/pet_profile/presentation/widgets/pet_timeline/**
flutter_app/lib/features/pet_profile/presentation/screens/pet_timeline_screen.dart
flutter_app/lib/features/pet_profile/presentation/providers/pet_timeline_providers.dart
flutter_app/test/features/pet_profile/**
```

**Scope:**

- Enable `PetTimelineDisplayOptions.full` in provider
- Gap fill action on fillable gap tiles
- Custody segments read-only in timeline
- Tests

**Exit criteria:**

- [ ] Custody and gap segments render with correct actions
- [ ] Widget tests green; PR merged

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "start phase 1: checkout cursor/pet-timeline-segments-a03d"
artifact_ref:
  branch: main
  plan_path: .agents/plans/pet-timeline-segments-a03d.md
  plan_commit: 390208e0ababec812543f707ee33a46043f0de04
  snapshot_path: .agents/plans/pet-timeline-segments-a03d.snapshot.json
  snapshot_commit: 390208e0ababec812543f707ee33a46043f0de04
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
