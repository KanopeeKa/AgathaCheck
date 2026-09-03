---
title: Canonical collection filtering
owner: Agent
audience: agent
status: active
last_updated: 2026-09-03
tags: [design, ux, filtering]
---

# Canonical collection filtering (`collection-filter-canonical-f8a2`)

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `collection-filter-canonical-f8a2` |
| **title** | Canonical progressive-disclosure collection filtering |
| **author** | Cloud agent (user design review 2026-09-03) |
| **created** | 2026-09-03 |
| **base_branch** | `cursor/collection-filter-canonical-integration-f8a2` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Replace chip-cloud collection filtering with a shared progressive-disclosure pattern across AgathaTrack. Filter categories stay visible; values appear on demand; active selections are removable chips. Preserve existing filter predicates and multi-select OR semantics. Pet Care Events (`/pc/events`) migrates first; org Events and other filter-heavy screens follow the same mechanism. No user-facing Sort control.

## Locked product decisions (2026-09-03)

| # | Decision |
|---|----------|
| 1 | **Multi-select OR** within each dimension — keep current predicate logic; expose via checkboxes in dimension menus, not radio simplification |
| 2 | **Org Events (`/o/events`)** uses the same collection-filter mechanism as Pet Care — not tab-based type navigation |
| 3 | **Live filtering** — every selection immediately updates the list; mobile sheet “Done” only dismisses |
| 4 | **Cohort collapsed** — My/Foster cohort is not a first-class toolbar chip; express via Pet dimension and/or “More filters” |
| 5 | **No Sort** — do not add a sort control on Events or as part of this pattern |
| 6 | **Active chips** — show only non-default selections (never “All pets”, never default `showSkipped: true`) |
| 7 | **Skipped** — meaningful active state is hiding skipped (`showSkipped: false`) |

## Autonomy (filled at approval)

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-03T07:36:00Z |
| **approved_until** | 2026-09-05T07:36:00Z |
| **control_issue** | [#884](https://github.com/KanopeeKa/AgathaCheck/issues/884) |
| **content_hash** | `sha256:8b191071a344b5cb2780dcc0c71852d4ae9768b34d04ea9c4a42c188079aca13` |
| **autonomy** | `active` |

**Grant:** user chat 2026-09-03 (locked decisions 1–4, no Sort) + `approve-autonomous collection-filter-canonical-f8a2` on #884

## UI design deep — scope summary

Full spec: `docs/design/collection-filter.md` (Phase 1 deliverable).

### Canonical pattern

| Breakpoint | Presentation |
|------------|----------------|
| **Desktop / wide** | Compact toolbar: `[ Pet ] [ Type ] [ Status ] [ More filters ]` + removable active-filter row when non-default |
| **Tablet** | Same model; overflow secondary dimensions into More when width tight |
| **Mobile** | `[ Filters n ]` opens structured bottom sheet; optional 0–1 quick filters only if justified |

### Shared behaviors

- Dimension triggers: `PopupMenuButton` / anchored menu with **checkbox multi-select** per dimension
- Active filter row: compact `InputChip` / dismiss chips; count badge on Filters button
- Reset: per-dimension clear inside menu + global “Clear all filters”
- Accessibility: focusable toolbar buttons, `Semantics` selected state, 48×48 targets
- Terminology: reuse existing l10n where possible (`allPets`, `dueAndOverdue`, etc.)

### Screens reviewed (migration map)

| Screen | Phase | Action |
|--------|-------|--------|
| Pet Care `/pc/events` | 2 | Migrate — primary target |
| Per-pet `/pet/:id/events` | 3 | Migrate (subset of dimensions) |
| Org `/o/events` | 3 | Migrate — replace tabbed `HealthDashboardScreen` shell with same list + toolbar |
| Legacy pet list org filter | 4 | Migrate `OrgFilterChips` |
| Health dashboard org filter (`/health`) | 4 | Migrate chip row |
| Vet list | 4 | Migrate; generalize existing >3 org dropdown pattern |
| Org pets secondary filters | 4 | Migrate filter row into More/sheet (keep tab chips) |
| Manage fosters approval | 4 | Migrate approval row |
| Notifications kind (3) | — | **Keep** — small-choice control |
| Org/manage-fosters **tabs** | — | **Keep** — primary navigation |
| Form ChoiceChips (remind, frequency) | — | **Keep** |

## Phases

### Phase 1 — Design spec + canonical widgets

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/collection-filter-foundation-f8a2` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/core/widgets/collection_filter/**
flutter_app/test/core/widgets/collection_filter/**
docs/design/collection-filter.md
docs/design/system.md
flutter_app/lib/l10n/**
.agents/plans/collection-filter-canonical-f8a2.md
.agents/plans/collection-filter-canonical-f8a2.snapshot.json
```

**forbidden_paths:**

```
server/**
.github/workflows/**
flutter_app/lib/features/**
```

**allowed_exceptions:**

```
tests
docs
file-split
governance-allowlist
```

**Scope:**

- `/ui-design-deep` deliverable: `docs/design/collection-filter.md` (9-part review + acceptance checklist)
- Implement reusable widgets: toolbar, dimension menu (checkbox multi-select), active filter chips row, mobile filter sheet, filter count badge, clear-all
- Generic `CollectionFilterController` / state adapter pattern (dimension id → selected value set)
- Widget tests for toolbar, sheet, active chips, accessibility semantics
- Add cross-reference in `docs/design/system.md`

**Exit criteria:**

- [ ] `docs/design/collection-filter.md` documents pattern, responsive rules, and locked decisions
- [ ] Core widgets exist under `core/widgets/collection_filter/` (each file ≤500 lines)
- [ ] Widget tests pass; `flutter analyze` clean for touched paths
- [ ] `./scripts/pre-push-changed.sh` green

---

### Phase 2 — Pet Care global Events

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/collection-filter-pc-events-f8a2` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `bdd-journey` |

**allowed_paths:**

```
flutter_app/lib/core/widgets/collection_filter/**
flutter_app/lib/features/experience/presentation/screens/guardian/global_events_list.dart
flutter_app/lib/features/experience/presentation/screens/guardian/guardian_due_events_screen.dart
flutter_app/lib/features/pet_profile/presentation/screens/widgets/manage_events_filters.dart
flutter_app/test/features/experience/presentation/screens/guardian/**
flutter_app/test/bdd/features/guardian_dashboard.feature
e2e/playwright/pages/health-dashboard.page.ts
e2e/playwright/tests/health.tracking.spec.ts
e2e/playwright/support/flutter.ts
flutter_app/lib/l10n/**
.agents/plans/collection-filter-canonical-f8a2.md
.agents/plans/collection-filter-canonical-f8a2.snapshot.json
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

- Replace `GuardianGlobalEventsFilterBar` + `ManageEventsFilterBar` on `/pc/events` with canonical toolbar + active chips + mobile sheet
- Wire to existing `GuardianGlobalEventsFilters` / `ManageEventsFilters` — **no predicate changes**
- Collapse cohort into Pet / More filters per locked decision #4
- Update widget tests (`guardian_due_events_screen_test`, `global_events_list_actions_test`)
- Update BDD + Playwright locators (stable keys on dimension triggers and active chips, not every value chip)
- Demo artifact: screen recording of desktop toolbar + mobile sheet on Events

**Exit criteria:**

- [ ] `/pc/events` has no multi-row chip cloud; list is visually dominant
- [ ] All prior filter capabilities preserved (multi-select OR, skipped toggle, pet scoping)
- [ ] BDD scenario “Global events screen supports pet and cohort filters” still passes (capability via Pet/More, not cohort chip row)
- [ ] `./scripts/pre-push-changed.sh` green

---

### Phase 3 — Per-pet Events + org Events

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/collection-filter-events-org-f8a2` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `bdd-journey` |

**allowed_paths:**

```
flutter_app/lib/core/widgets/collection_filter/**
flutter_app/lib/features/pet_profile/presentation/screens/pet_manage_events_screen.dart
flutter_app/lib/features/pet_profile/presentation/screens/widgets/manage_events_filter_bar.dart
flutter_app/lib/features/pet_profile/presentation/screens/widgets/pet_event_entry_list.dart
flutter_app/lib/core/router/experience_routes.dart
flutter_app/lib/features/health_tracking/presentation/screens/health_dashboard_screen.dart
flutter_app/lib/features/health_tracking/domain/health_events_scope.dart
flutter_app/test/features/pet_profile/presentation/screens/pet_manage_events_screen_test.dart
flutter_app/test/core/router/**
e2e/playwright/pages/health-dashboard.page.ts
e2e/playwright/tests/organisation.pet.management.spec.ts
flutter_app/lib/l10n/**
.agents/plans/collection-filter-canonical-f8a2.md
.agents/plans/collection-filter-canonical-f8a2.snapshot.json
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

- Migrate `PetManageEventsScreen` / `ManageEventsList` to canonical filter (Type, Status, Recurrence, Skipped — no pet row)
- Replace org `/o/events` (`_OrgEventsScreen` → tabbed `HealthDashboardScreen`) with unified filtered events list + same toolbar pattern (org-scoped pets, org filter in More if needed)
- Mark `ManageEventsFilterBar` / `GuardianGlobalEventsFilterBar` `@Deprecated` pointing to canonical widgets
- Update tests and org Events E2E paths

**Exit criteria:**

- [ ] Per-pet manage events uses canonical filter UI
- [ ] `/o/events` uses same collection-filter mechanism as `/pc/events` (no type TabBar)
- [ ] Deprecated annotations on obsolete filter bar widgets
- [ ] `./scripts/pre-push-changed.sh` green

---

### Phase 4 — Secondary screens + deprecation cleanup

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/collection-filter-rollout-f8a2` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `bdd-journey` |

**allowed_paths:**

```
flutter_app/lib/core/widgets/collection_filter/**
flutter_app/lib/features/pet_profile/presentation/widgets/org_filter_chips.dart
flutter_app/lib/features/pet_profile/presentation/screens/pet_list_screen.dart
flutter_app/lib/features/health_tracking/presentation/widgets/health_dashboard/health_dashboard_org_filter.dart
flutter_app/lib/features/vet/presentation/widgets/vet_filter_bar.dart
flutter_app/lib/features/vet/presentation/screens/vet_list_screen.dart
flutter_app/lib/features/organization/presentation/widgets/org_pets/org_pets_filter_row.dart
flutter_app/lib/features/organization/presentation/screens/manage_fosters/manage_fosters_screen.dart
flutter_app/test/features/pet_profile/presentation/widgets/org_filter_chips_test.dart
flutter_app/test/features/health_tracking/presentation/widgets/health_dashboard/health_dashboard_org_filter_test.dart
flutter_app/test/bdd/features/pet_screen_filters.feature
e2e/playwright/tests/organisation.pet-filters.spec.ts
e2e/playwright/tests/health.tracking.spec.ts
docs/design/collection-filter.md
docs/design/system.md
.agents/plans/collection-filter-canonical-f8a2.md
.agents/plans/collection-filter-canonical-f8a2.snapshot.json
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

- Migrate: legacy `OrgFilterChips`, `HealthDashboardOrgFilter`, `VetFilterBar`, `OrgPetsFilterRow` (secondary filters only), manage-fosters approval filters
- **Retain** notification kind chips, org/manage-fosters tab chips, form ChoiceChips
- Remove dead code paths where migration complete; keep `@Deprecated` shims one phase if needed for imports
- Final E2E sweep for filter locators

**Exit criteria:**

- [ ] Filter-heavy screens listed in design doc use canonical pattern
- [ ] Chip-cloud pattern removed from migrated screens
- [ ] `./scripts/pre-push.sh` green before integration→main PR
- [ ] Integration branch PR to `main` via `/babysit-uat`

---

## Integration → main

After phase 4 merges into `cursor/collection-filter-canonical-integration-f8a2`:

1. Open one PR: integration → `main`
2. Run `./scripts/pre-push.sh`
3. `/babysit-uat` (final merge + pre-UAT E2E)

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/collection-filter-foundation-f8a2"
artifact_ref:
  branch: cursor/collection-filter-canonical-integration-f8a2
  plan_path: .agents/plans/collection-filter-canonical-f8a2.md
  plan_commit: e6d1f7cf1d4e7f9297a79c04291ab8981a9f6bb8
  snapshot_path: .agents/plans/collection-filter-canonical-f8a2.snapshot.json
  snapshot_commit: e6d1f7cf1d4e7f9297a79c04291ab8981a9f6bb8
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Sanity check expectations

**Assessment:** `proceed-high-risk`

| Factor | Notes |
|--------|-------|
| Scope | 4 phases, Flutter-only, cross-cutting UI — fits medium feature with integration branch |
| Risk | Org `/o/events` replaces tabbed dashboard — behavior must stay equivalent via filters |
| Duplication | Phase 1 foundation reduces drift |
| CI | BDD/E2E locator updates in phases 2–4 |
| Blockers | None — decisions locked |

Output: **`proceed-high-risk`** — approved autonomy recommended with integration branch and `/babysit-uat` on final merge.

## Revoke and resume

| Action | How |
|--------|-----|
| **Revoke** | Add `autonomous-revoked` on control issue |
| **Resume** | Remove revoke; comment `resume-plan collection-filter-canonical-f8a2` |

## Checklist before `approve-autonomous`

- [ ] Snapshot validates: `node scripts/validate_execute_plan_snapshot.js .agents/plans/collection-filter-canonical-f8a2.snapshot.json`
- [ ] Control issue created with labels `execute-plan`, `plan:collection-filter-canonical-f8a2`, `autonomous-approved`
- [ ] `default_merge_mode: auto` on snapshot
- [ ] Integration branch created from `main`
