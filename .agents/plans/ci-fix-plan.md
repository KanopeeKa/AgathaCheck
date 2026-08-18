# CI & Code Review Fix Plan

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `ci-fix-plan` |
| **title** | Fix CI and Code Reviews for UX Overhaul |
| **author** | Cloud Agent |
| **created** | 2026-08-18 |
| **base_branch** | `cursor/ux-overhaul-integration-13e3` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Address the CI failures and code review comments on the UX Overhaul PRs (646, 648, 649). This includes fixing the hard-coded `AppExperience.guardian` in `pet_detail_viewer_context_provider.dart` which prevents org-admin users from accessing privileged actions. We will also update dependabot PRs if necessary to ensure a clean build.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-08-18T14:17:00Z |
| **approved_until** | 2026-08-20T14:17:00Z |
| **control_issue** | 2 |
| **content_hash** | pending |
| **autonomy** | `active` |

## Phases

### Phase 1 — Fix Code Review & CI

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/ci-fix-phase1-13e3` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:**
```
flutter_app/lib/features/pet_profile/presentation/providers/pet_detail_viewer_context_provider.dart
flutter_app/test/features/experience/presentation/providers/resolve_post_login_path_test.dart
flutter_app/lib/features/experience/presentation/providers/experience_providers.dart
flutter_app/lib/features/experience/presentation/screens/experience_resolve_screen.dart
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
- Fix the hard-coded `AppExperience.guardian` in `pet_detail_viewer_context_provider.dart` to correctly resolve the experience based on pet/org data.
- Ensure all tests pass and `flutter analyze` is green.
- Address any other lingering CI issues on the integration branch.

**Exit criteria:**
- [ ] Code review comment addressed.
- [ ] `flutter analyze` passes.
- [ ] Tests pass.

## Runtime state

```yaml
autonomy: completed
current_phase: null
last_completed_phase: 1
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: cursor/ux-overhaul-integration-13e3
  plan_path: .agents/plans/ci-fix-plan.md
  plan_commit: 594bb55158edad7b10b97dd6ffd08b3a0743b5a5
  snapshot_path: .agents/plans/ci-fix-plan.snapshot.json
  snapshot_commit: 594bb55158edad7b10b97dd6ffd08b3a0743b5a5
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
