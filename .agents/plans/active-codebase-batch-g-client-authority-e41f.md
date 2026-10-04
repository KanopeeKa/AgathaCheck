---
title: Active codebase Batch G — Client authority (pet freshness + health commands)
owner: Agent
audience: agent
status: proposed
last_updated: 2026-09-29
---

# active-codebase-batch-g-client-authority-e41f

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `active-codebase-batch-g-client-authority-e41f` |
| **roadmap** | [`active-codebase-completion-e41f`](./active-codebase-completion-e41f.md) |
| **base_branch** | `cursor/active-codebase-g-integration-e41f` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **parallel-eligible with** | Batches E and F (Flutter-only, disjoint paths except the l10n ARB files, which F.4 also edits; if run in parallel, merge F before G's integration PR and resolve ARB conflicts with `flutter gen-l10n`) |
| **router risk** | R2 — protocols `flutter-mobile`, `accessibility`, `testing`, `date-time` |

## Entry gate (coordination, `docs/agent-efficiency/parallel-programmes.md`)

- Landing slot **7**. Bootstrap only after **CARE E+F** (slot 5b) have landed. **Re-baseline Package 8 first**: CARE F's Care Item module changes the health store and occurrence widgets, so re-measure the direct repository calls and the store's refresh semantics on `main` and shrink or close G.2/G.3 accordingly before implementing. The "parallel-eligible with E and F" note in the metadata is superseded by this gate.

## Goal

Finish Packages 7 and 8 (D2, D18, D19):

- Cached pet data carries a **real** sync time and an explicit freshness state, visible on every pet surface.
- The canonical health store keeps last-good data through refresh failures and cannot be overwritten by stale or out-of-session responses.
- Every health mutation goes through a `CareScheduleController` instead of widgets, so a committed command is never reported as a failure because its refresh failed.

## Autonomy (filled at bootstrap)

| Field | Value |
|-------|-------|
| **approved_by** | standing grant — roadmap `active-codebase-completion-e41f` |
| **approved_at / approved_until** | set at bootstrap (+48h) |
| **control_issue** | set at bootstrap |

## Runtime

```yaml
autonomy: active
current_phase: 4
last_completed_phase: 3
halt_reason: null
next_action: "continue phase 4 on branch cursor/active-codebase-g4-offline-e2e-e41f"
artifact_ref:
  branch: cursor/active-codebase-g3-care-schedule-controller-e41f
  plan_path: .agents/plans/active-codebase-batch-g-client-authority-e41f.md
  plan_commit: 57d5efeccb2520d79db6c6ee9ab74a0d08df7dee
  snapshot_path: .agents/plans/active-codebase-batch-g-client-authority-e41f.snapshot.json
  snapshot_commit: 57d5efeccb2520d79db6c6ee9ab74a0d08df7dee
open_prs: []
merge_commits: {"2":"dba43f7da365f0aa59e05ee1c47b1334089e33d4"}
debt_issue_refs: []
```

## Phases

### Phase 1 — Pet cache freshness (Package 7 completion)

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/active-codebase-g1-pet-freshness-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-g-client-authority-e41f.*
flutter_app/lib/features/pet_profile/data/**
flutter_app/lib/features/pet_profile/domain/**
flutter_app/lib/features/pet_profile/presentation/providers/**
flutter_app/lib/features/pet_profile/presentation/widgets/pet_list/pet_list_stale_banner.dart
flutter_app/lib/features/pet_profile/presentation/screens/pet_detail_screen.dart
flutter_app/lib/features/experience/presentation/screens/experience_home_screens.dart
flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_all_pets_screen.dart
flutter_app/lib/l10n/app_en.arb
flutter_app/lib/l10n/app_fr.arb
flutter_app/lib/l10n/app_localizations.dart
flutter_app/lib/l10n/app_localizations_en.dart
flutter_app/lib/l10n/app_localizations_fr.dart
flutter_app/test/features/pet_profile/**
flutter_app/test/features/experience/**
```

**forbidden_paths:**

```
server/**
e2e/**
.github/workflows/**
flutter_app/lib/features/health_tracking/**
```

**allowed_exceptions:**

```
tests
docs
file-split
```

**Scope:** persist `lastSyncedAt`, fix `fetchedAt`, add a freshness state and banners, migrate pet detail. This phase also adds the l10n string used by G.3 (`careCommandSavedRefreshFailed`, EN + FR) so that later phases do not touch the ARB files.

**Acceptance criteria:**

- [ ] **G.1-1** The local datasource persists `lastSyncedAt` (UTC) per user scope after each successful remote fetch, and clears it with the cache on logout or user switch.
- [ ] **G.1-2** For cached results, `PetListFetchResult.fetchedAt` is the persisted `lastSyncedAt`, or `null` when unknown (legacy cache). It is **never** `DateTime.now()` for cached data (regression test for `pet_repository_impl.dart:94`).
- [ ] **G.1-3** `freshness` ∈ `fresh` (remote in this call) \| `stale` (cache ≤ 7 days) \| `expired` (> 7 days) \| `unknown` (no timestamp), per D18. The local-only / no-token path never reports `fresh` and never reports `isStale: false`.
- [ ] **G.1-4** Banners: `stale` shows an info banner, "Offline — showing pets saved <relative time>". `expired` and `unknown` show a warning banner, "Saved data may be out of date", with a **Retry** button that has a semantics label and triggers a refetch. EN and FR strings.
- [ ] **G.1-5** Home, All Pets and **pet detail** show the indicator whenever their pet data came from cache (one widget test per surface).
- [ ] **G.1-6** The D2 classification is unchanged: 401, 403, 5xx and parse errors throw. Existing D2 tests and the server-authoritative pruning test (online deletion stays deleted) pass.
- [ ] **G.1-7** User-switch test: user A's cached pets and freshness metadata are never shown to user B.

---

### Phase 2 — Health store refresh and session semantics (Package 8, store)

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/active-codebase-g2-health-store-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-g-client-authority-e41f.*
flutter_app/lib/features/health_tracking/presentation/providers/health_providers.dart
flutter_app/lib/features/health_tracking/presentation/providers/health_entries_store*.dart
flutter_app/lib/features/health_tracking/domain/entities/command_outcome.dart
flutter_app/test/features/health_tracking/presentation/providers/**
```

**forbidden_paths:**

```
server/**
e2e/**
.github/workflows/**
flutter_app/lib/features/pet_profile/**
flutter_app/lib/features/health_tracking/presentation/widgets/**
```

**allowed_exceptions:**

```
tests
file-split
```

**Scope:** make `HealthEntriesNotifier` refreshes keep previous data, guard against out-of-order and out-of-session responses, and return a `CommandOutcome` (D19).

**Acceptance criteria:**

- [ ] **G.2-1** `refresh()` keeps the previous value while loading and on failure (`AsyncLoading` / `AsyncError` with the previous value), so every selector keeps rendering last-good data. This fixes `health_providers.dart:105`.
- [ ] **G.2-2** Request-generation guard: every fetch captures a generation, and results from superseded generations are dropped. Test: two overlapping fetches that resolve out of order → the newest wins.
- [ ] **G.2-3** Session guard: logout or user switch bumps the session id and clears state. A fetch started before logout never writes after it (test with a delayed fake repository).
- [ ] **G.2-4** Every command method (create, updateEntry, delete, markTaken, undoComplete, closeEvent, reopenEvent, pauseCareItem, resumeCareItem, unmarkDone) returns `CommandOutcome { committed: true, refreshFailed }`. A refresh failure after a successful command does **not** throw; a command failure still throws. One test per command family, using a fake repository.
- [ ] **G.2-5** No optimistic updates (D19). The filtered, per-pet-by-id and due/overdue selectors converge after each command (existing canonical-store tests plus new ones).
- [ ] **G.2-6** An entry deleted while an older fetch is in flight does not reappear when that older fetch resolves (test).

---

### Phase 3 — CareScheduleController and widget migration (Package 8, commands)

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/active-codebase-g3-care-schedule-controller-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-g-client-authority-e41f.*
flutter_app/lib/features/health_tracking/presentation/controllers/care_schedule_controller*.dart
flutter_app/lib/features/health_tracking/presentation/widgets/**
flutter_app/lib/features/health_tracking/presentation/screens/**
flutter_app/lib/features/health_tracking/presentation/providers/pet_event_view_providers.dart
flutter_app/lib/features/health_tracking/presentation/providers/occurrence_providers.dart
flutter_app/lib/features/pet_care/context/presentation/widgets/away_plan_suggestions_section.dart
flutter_app/test/features/health_tracking/presentation/controllers/**
flutter_app/test/features/health_tracking/presentation/widgets/**
flutter_app/test/features/pet_care/**
flutter_app/test/architecture/health_presentation_boundary_test.dart
```

**forbidden_paths:**

```
server/**
e2e/**
.github/workflows/**
flutter_app/lib/l10n/**
```

**allowed_exceptions:**

```
tests
file-split
```

**Scope:** move the 15 direct repository calls in 10 files into `CareScheduleController`. Files: `occurrence_care_actions.dart`, `weight_occurrence_care_actions.dart`, `reschedule_occurrence_flow.dart`, `occurrence_review_flow.dart`, `occurrence_add_details_sheet.dart`, `occurrence_completion_feedback.dart`, `pet_event_occurrence_actions.dart`, `pet_event_view_providers.dart` (move under `providers/`), `health_dashboard_screen.dart` (CSV export through a query provider), `away_plan_suggestions_section.dart`. Also move the issue-linking flow (`health_issue_prompt/health_issue_linkage_flow.dart`).

**Acceptance criteria:**

- [ ] **G.3-1** `CareScheduleController` owns: complete occurrence (including `skipEarlierMissed`), skip all missed, reschedule, occurrence review and add-details, weight occurrence completion, and issue link/unlink. Each returns `CommandOutcome` and reconciles `entryOccurrencesProvider` and the canonical store in **one** place.
- [ ] **G.3-2** An architecture test (`flutter_app/test/architecture/health_presentation_boundary_test.dart`) fails if any file under `health_tracking/presentation/{widgets,screens}/**` or `pet_care/**/presentation/widgets/**` reads `healthRepositoryProvider`, `healthRemoteDataSourceProvider` or `healthDataSourceProvider`, or calls `ref.invalidate` on health providers.
- [ ] **G.3-3** UI outcome: when committed, show success; when committed but `refreshFailed`, show success plus the non-blocking "Saved — couldn't refresh. Pull to refresh." (string added in G.1); show failure only when the command did not commit. Duplicate taps on the same occurrence are ignored while its command is in flight (widget test).
- [ ] **G.3-4** Issue linking goes through the controller, and the linked state is visible in both per-pet and global views immediately after the command, with no widget-level invalidation (test).
- [ ] **G.3-5** Controller unit tests, using a fake repository, cover success, command failure, refresh failure, and disposal mid-command (no state write after dispose).
- [ ] **G.3-6** `node scripts/check_feature_imports.js` baseline does not grow; any identities removed by the move are ratcheted out.

---

### Phase 4 — Offline cache journey (BDD + Playwright)

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/active-codebase-g4-offline-e2e-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `bdd-journey` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-g-client-authority-e41f.*
flutter_app/test/bdd/features/pet_offline_cache.feature
e2e/playwright/tests/pet.offline-cache.spec.ts
e2e/playwright/pages/pet-list.page.ts
e2e/scripts/shard-files.mjs
```

**forbidden_paths:**

```
server/**
flutter_app/lib/**
.github/workflows/**
```

**allowed_exceptions:**

```
tests
docs
```

**Scope:** journey coverage for D2 and D18 using Playwright route interception.

**Acceptance criteria:**

- [ ] **G.4-1** Scenario "Pet list shows saved pets with an offline banner when the network fails": after a successful first load, requests to `**/api/pets**` are aborted and the page is reloaded. Cached pets and the offline banner are visible. After the route is restored and **Retry** is pressed, the banner disappears.
- [ ] **G.4-2** Scenario "Pet list does not show cached pets when the session is rejected": `**/api/pets**` returns 401, and the app shows the auth-failure path, not the cached list.
- [ ] **G.4-3** The spec is registered in `e2e/scripts/shard-files.mjs` and tagged `@P1`. `check_bdd_coverage.js`, `check_bdd_priority_tags.js` and `validate-shard-manifest.mjs` pass, and the `@bdd` titles match the Gherkin exactly.

---

### Phase 5 — Integration → main + pre-UAT

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/active-codebase-g-integration-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
**
```

**forbidden_paths:**

```
.github/workflows/deploy-*.yml
```

**allowed_exceptions:**

```
tests
docs
```

**Scope:** open one PR from the integration branch into `main`; `./scripts/pre-push.sh`; `/babysit-uat`; pre-UAT watch; `complete-plan`; `roadmap-set-child`.

**Acceptance criteria:**

- [ ] **G.5-1** Phases 1–4 are merged into the integration branch, and the integration → `main` PR is merged by `/babysit-uat`, with the Flutter analyze, test shards and coverage jobs green.
- [ ] **G.5-2** Pre-UAT E2E is green on the merge SHA, including the occurrence completion, reschedule, away-plan and the new offline-cache specs.
- [ ] **G.5-3** The roadmap child status is `merged`, and the rows for Packages 7 and 8 read Done.
