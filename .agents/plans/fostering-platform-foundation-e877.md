# Plan — Fostering platform foundation (post-G0)

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `fostering-platform-foundation-e877` |
| **title** | Fostering platform foundation — migration appendix + J1 Manage Fosters shell |
| **author** | cloud-agent |
| **created** | 2026-07-24 |
| **base_branch** | `cursor/fostering-platform-foundation-e877-integration` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

After G0 contract pack merge (#330), deliver the two foundation artefacts that unblock journey implementation: a locked **migration appendix** (J3 gate) and **J1 Phase 1** Manage Fosters operational screen shell with BDD skeleton — all on an integration branch with atomic phase PRs.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-07-24T23:50:00Z |
| **approved_until** | 2026-07-26T23:50:00Z |
| **control_issue** | (set in snapshot) |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous fostering-platform-foundation-e877`

---

## Phase 1 — Migration appendix

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/fostering-migration-appendix-e877` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
docs/fostering-platform/**
.agents/plans/fostering-platform-foundation-e877.*
```

**forbidden_paths:**

```
flutter_app/**
server/**
db/migrations/**
.github/workflows/**
```

**Scope:**

- `migration-appendix.md` with locked G0 §12 dispositions
- Status maps current → target (no undefined statuses)
- Unique index definition for one open session per pet
- Dual-write / sunset criteria for legacy placement statuses
- `foster_user_id NOT NULL` resolution path

**Exit criteria:**

- [ ] All G0 §12 entities marked `locked`
- [ ] Session status enum internally consistent with G0 §6
- [ ] README index updated

---

## Phase 2 — J1 Manage Fosters shell

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/j1-manage-fosters-shell-e877` |
| **exit_checklist** | `flutter-screen-split` + `bdd-journey` |

**allowed_paths:**

```
flutter_app/lib/features/organization/presentation/screens/manage_fosters/**
flutter_app/lib/features/organization/presentation/widgets/manage_fosters/**
flutter_app/lib/features/organization/presentation/providers/manage_fosters_providers.dart
flutter_app/lib/l10n/**
flutter_app/test/features/organization/presentation/screens/manage_fosters/**
flutter_app/test/features/organization/presentation/widgets/manage_fosters/**
flutter_app/test/bdd/features/foster_onboarding.feature
docs/fostering-platform/j1-foster-onboarding.md
.agents/plans/fostering-platform-foundation-e877.*
```

**forbidden_paths:**

```
server/**
db/**
.github/workflows/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope:**

- Dedicated Manage Fosters screen (tabs + approval filters UI)
- Activity tab labels derived from existing `active_pets` / placement statuses (J3 read-model placeholder)
- Rename user-facing "external foster" → "Add foster manually" (l10n)
- Navigation from org detail
- Gherkin skeleton + widget tests (no Playwright until API stable — debt if needed)

**Exit criteria:**

- [ ] Manage Fosters screen reachable from org area
- [ ] Tabs: New, Fostering, Recently fostered, Inactive, All
- [ ] Filters: Under review, Approved, Archived (UI; approval backend stubbed/placeholder until J1 Phase 2)
- [ ] Foster summary cards list from existing foster-parents API
- [ ] Widget tests pass; `flutter analyze` clean for touched files
- [ ] BDD feature file with ≥3 scenarios (may be unmapped initially with debt issue)

---

## Runtime state

```yaml
autonomy: active
current_phase: 2
last_completed_phase: 1
halt_reason: null
next_action: "continue phase 2 on branch cursor/j1-manage-fosters-shell-e877"
artifact_ref:
  branch: cursor/j1-manage-fosters-shell-e877
  plan_path: .agents/plans/fostering-platform-foundation-e877.md
  plan_commit: 5a6c706022b7ed7a66c787c380fc0701c3158ad3
  snapshot_path: .agents/plans/fostering-platform-foundation-e877.snapshot.json
  snapshot_commit: 5a6c706022b7ed7a66c787c380fc0701c3158ad3
open_prs: []
merge_commits: {"1":"5a6c706022b7ed7a66c787c380fc0701c3158ad3"}
debt_issue_refs: []
```
