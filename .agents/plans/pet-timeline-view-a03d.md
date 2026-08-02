# Pet timeline view — execute-plan

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `pet-timeline-view-a03d` |
| **title** | Custom pet timeline view with year dividers |
| **author** | cloud-agent |
| **created** | 2026-08-02 |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Replace the pet Timeline screen list-of-cards layout with a custom vertical timeline (spine, nodes, subtle year dividers), newest-first, preserving all v1 CRUD and read-only entry types. Architect display filtering so custody/gap segments can plug in later without rewiring the view.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-08-02T16:56:00Z |
| **approved_until** | 2026-08-04T16:56:00Z |
| **approved_by** | user chat standing grant |
| **autonomy** | `active` |

## Phases

### Phase 1 — Custom timeline view

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/pet-timeline-view-a03d` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/pet_profile/presentation/widgets/pet_timeline/**
flutter_app/lib/features/pet_profile/presentation/screens/pet_timeline_screen.dart
flutter_app/test/features/pet_profile/**
```

**forbidden_paths:**

```
server/**
.github/workflows/**
```

**Scope:**

- Custom `PetTimelineView` with spine, per-kind nodes, year dividers
- `PetTimelineDisplayOptions` for future custody/gap inclusion
- Preserve add/edit/delete, test keys, newest-first sort

**Exit criteria:**

- [ ] Timeline screen renders vertical timeline with year dividers
- [ ] Widget tests green; `./scripts/pre-push-changed.sh` passes
- [ ] PR merged via babysit+

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/pet-timeline-view-a03d"
artifact_ref:
  branch: cursor/pet-timeline-view-a03d
  plan_path: .agents/plans/pet-timeline-view-a03d.md
  plan_commit: 2669a89838bfc1dd1f60cc08adb9b74567ef080c
  snapshot_path: .agents/plans/pet-timeline-view-a03d.snapshot.json
  snapshot_commit: 2669a89838bfc1dd1f60cc08adb9b74567ef080c
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/531"]
merge_commits: {}
debt_issue_refs: []
```
