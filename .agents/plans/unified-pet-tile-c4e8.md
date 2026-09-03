---
title: Unified pet tile and Care dashboard carousel
owner: Agent
audience: agent
status: draft
last_updated: 2026-09-03
tags: [design, guardian, pets, shelter, ui]
---

# Unified pet tile and Care dashboard carousel (`unified-pet-tile-c4e8`)

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `unified-pet-tile-c4e8` |
| **title** | Unified pet tile (Care + Shelter) and uncapped Care dashboard carousel |
| **author** | Cloud agent (user design review 2026-09-03) |
| **created** | 2026-09-03 |
| **base_branch** | `cursor/unified-pet-tile-integration-c4e8` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Replace the split pet-tile implementations (`PetCard` vertical tiles vs `GuardianDashboardPetCard` horizontal tiles) with one cross-domain **unified pet tile**, fix the Care dashboard pet rail so **all active shell pets** appear in a scrollable carousel (no 4-pet cap), add **My Pets** eyebrow + always-visible **All pets** link, web **scroll arrows**, and collapse passed-away pets on the All pets screen behind a localized expansion section with wing overlay on tiles.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-03T22:18:00Z |
| **approved_until** | 2026-09-05T22:18:00Z |
| **control_issue** | #950 |
| **content_hash** | see snapshot |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous unified-pet-tile-c4e8`

## Design decisions (locked — user review 2026-09-03)

| ID | Decision |
|----|----------|
| D1 | **Carousel shows all** active `guardianShellPets` (no cap); passed-away excluded from carousel |
| D2 | **Tile size:** ~140px tall × 120–172px wide (responsive width); rail height grows to fit |
| D3 | **Stripe:** keep 4px ownership accent strip (`resolvePetOwnershipAccent`) |
| D4 | **Line 1:** pet name. **Line 2:** context-aware (see D5/D6) |
| D5 | **Pet Care surfaces:** line 2 = care urgency **or** “All clear” (`GuardianTodayPetCareState` wording) |
| D6 | **Shelter surfaces:** line 2 = foster placement/session (`petFosterPlacementCardLine`) when relevant; else `OrgPetAttentionReason` label (folded into tile — remove below-tile attention text) |
| D7 | **Eyebrow:** `myPets` / “My Pets” (not “Furry Friends”) |
| D8 | **All pets link:** always visible on Care dashboard section chrome |
| D9 | **Sort:** hybrid — attention-first on Care dashboard rail; creation/name order on Shelter grids and All pets grid |
| D10 | **Add pet tile:** keep at end of carousel |
| D11 | **Web arrows:** subtle left/right chevrons on fine-pointer viewports; swipe on touch |
| D12 | **Passed-away (All pets):** collapsed `ExpansionTile` by default; EN **“Rainbow bridge”** / FR **“Au-delà des nuages”** (new l10n key); unified tile inside; small **wings** overlay top-right on photo (`assets/rainbow_wings.png`, ~24px, ~0.85 opacity) |
| D15 | **Care line 2:** icon + semantic colour paired with text (not colour alone) |
| D16 | **`PetCard` migration:** thin delegate to `UnifiedPetTile` in phase 5 |
| D13 | **Scope:** cross-domain (Care dashboard, All pets, Shelter org lists, legacy pet-list sections using `PetCard`) |
| D14 | **Blueprint:** update Card H + related design docs in final phase |

### Unified tile anatomy

```text
┌─┬──────────────────┐
│█│  [wings if PA]   │  ← 4px stripe; passed-away: wings top-right on photo
│█│     Photo        │  ← ~⅔ height (~90–100px at 140px tile)
│█├──────────────────┤
│█│ Pet name         │  ← line 1, ellipsis
│█│ Status line      │  ← line 2, coloured on Pet Care (care urgency)
└─┴──────────────────┘
   120–172px wide × ~140px tall (height may grow with text scale)
```

### Status line resolver (new pure module)

| Mode | Priority for line 2 |
|------|----------------------|
| `petCare` | `guardianTodayPetCareState` label (overdue / due today / upcoming / all clear) |
| `shelter` | `petFosterPlacementCardLine` → else `localizedAttentionReason` → else omit |

Passed-away tiles: lifecycle treatment on photo; line 2 = `passedAway` label; suppress care urgency colours.

## Sanity check

**Estimate:** `proceed-high-risk` — 5 phases, cross-domain Flutter, widget test + semantics churn, blueprint update. Fits medium feature if executed via integration branch; may need re-approval if `approved_until` exceeded.

**Risks flagged:**

- Wide blast radius across `pet_profile`, `experience`, `organization` features
- Existing tests assert 4-pet cap and horizontal `GuardianDashboardPetCard` layout
- Legacy non-embedded `PetListScreen` path still uses `PetCard` — included in scope (D13)
- `GuardianShellSharedPetCard` is a no-op wrapper — remove during cleanup
- Deprecate `GuardianDashboardPetCard` and `GuardianFullListPetCard` after migration

## Phases

### Phase 1 — Unified tile widget and status resolver

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/unified-pet-tile-foundation-c4e8` |
| **exit_checklist** | `default` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
flutter_app/lib/features/pet_profile/presentation/widgets/unified_pet_tile.dart
flutter_app/lib/features/pet_profile/presentation/widgets/pet_tile_status_line.dart
flutter_app/lib/features/pet_profile/presentation/utils/pet_tile_dimensions.dart
flutter_app/test/features/pet_profile/presentation/widgets/unified_pet_tile_test.dart
flutter_app/test/features/pet_profile/presentation/widgets/pet_tile_status_line_test.dart
.agents/plans/unified-pet-tile-c4e8.md
.agents/plans/unified-pet-tile-c4e8.snapshot.json
```

**forbidden_paths:**

```
server/**
.github/workflows/**
flutter_app/lib/features/experience/**
flutter_app/lib/features/organization/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope:**

- Add `UnifiedPetTile` with stripe, photo, two-line text, passed-away photo treatment + wings overlay
- Add `PetTileStatusLine` resolver (`PetTileContext.petCare` | `PetTileContext.shelter`)
- Add `pet_tile_dimensions.dart` for 140×120–172 responsive sizing + a11y height growth
- Widget tests: layout constraints, line 2 per context, passed-away wings, stripe colours
- **No consumer migration yet** — foundation only

**Exit criteria:**

- [ ] `UnifiedPetTile` renders at target dimensions with stripe + 2 lines
- [ ] Status resolver covered for care urgency, foster line, org attention, passed-away
- [ ] `flutter test` on new tests green
- [ ] `./scripts/pre-push-changed.sh` green

---

### Phase 2 — Care dashboard rail (uncapped carousel + chrome + arrows)

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/care-pet-rail-carousel-c4e8` |
| **exit_checklist** | `bdd-journey` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
flutter_app/lib/features/experience/presentation/widgets/guardian_shell_home_content.dart
flutter_app/lib/features/experience/presentation/screens/guardian/guardian_my_pets_section.dart
flutter_app/lib/features/experience/presentation/screens/guardian/guardian_dashboard_helpers.dart
flutter_app/lib/features/experience/presentation/widgets/guardian_dashboard_section_header.dart
flutter_app/lib/features/experience/presentation/widgets/horizontal_carousel_controls.dart
flutter_app/lib/features/pet_profile/presentation/widgets/unified_pet_tile.dart
flutter_app/lib/features/pet_profile/presentation/widgets/pet_tile_status_line.dart
flutter_app/lib/features/pet_profile/presentation/utils/pet_tile_dimensions.dart
flutter_app/test/features/experience/**
flutter_app/lib/l10n/**
.agents/plans/unified-pet-tile-c4e8.md
.agents/plans/unified-pet-tile-c4e8.snapshot.json
```

**forbidden_paths:**

```
server/**
.github/workflows/**
flutter_app/lib/features/organization/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope:**

- Remove `GuardianTodayPetPreview.visibleLimit` cap and loading-path `.take(4)`
- Rail lists **all** active shell pets (attention-first sort); keep add-pet tile at end
- `GuardianDashboardSectionChrome`: title `myPets` **always**; `allPets` link **always**
- Replace `GuardianDashboardPetCard` in `_GuardianPetRail` with `UnifiedPetTile` (`petCare` context + `careSummary`)
- Rail height → ~140px (grow with text scale)
- Add `HorizontalCarouselControls` (subtle chevrons, fine pointer, disabled at extents, a11y)
- Update/remove tests asserting 4-pet cap

**Exit criteria:**

- [ ] Dashboard rail shows all active pets (widget test with 9 pets)
- [ ] “My Pets” eyebrow + “All pets” link always visible
- [ ] Web arrows scroll rail; touch swipe unchanged
- [ ] No `GuardianDashboardPetCard` in dashboard rail
- [ ] `./scripts/pre-push-changed.sh` green

---

### Phase 3 — Care All pets screen + passed-away collapse

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/care-all-pets-unified-tile-c4e8` |
| **exit_checklist** | `bdd-journey` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
flutter_app/lib/features/pet_profile/presentation/widgets/pet_list/**
flutter_app/lib/features/experience/presentation/widgets/guardian_pets_tile_grid.dart
flutter_app/lib/features/pet_profile/presentation/widgets/unified_pet_tile.dart
flutter_app/lib/features/pet_profile/presentation/widgets/pet_tile_status_line.dart
flutter_app/lib/features/pet_profile/presentation/utils/pet_tile_dimensions.dart
flutter_app/lib/features/pet_profile/presentation/screens/pet_list_screen.dart
flutter_app/test/features/pet_profile/**
flutter_app/test/features/experience/presentation/widgets/guardian_pets_tile_grid_test.dart
flutter_app/lib/l10n/**
.agents/plans/unified-pet-tile-c4e8.md
.agents/plans/unified-pet-tile-c4e8.snapshot.json
```

**forbidden_paths:**

```
server/**
.github/workflows/**
flutter_app/lib/features/organization/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope:**

- `GuardianPetsTileGrid` → `UnifiedPetTile` (petCare context); creation-order sort
- `GuardianPassedAwaySection` → collapsed `ExpansionTile` (new l10n: EN “Rainbow bridge”, FR “Au-delà des nuages”)
- Passed-away rows use unified tile with wings overlay
- Remove `GuardianDashboardPetCard` from embedded All pets path

**Exit criteria:**

- [ ] All pets grid uses unified tile at target dimensions
- [ ] Passed-away section collapsed by default; expands to unified tiles with wings
- [ ] l10n keys added; FR matches user spec
- [ ] `./scripts/pre-push-changed.sh` green

---

### Phase 4 — Shelter org surfaces

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/shelter-unified-pet-tile-c4e8` |
| **exit_checklist** | `default` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
flutter_app/lib/features/organization/presentation/widgets/org_pets/**
flutter_app/lib/features/organization/presentation/screens/organization_pets_screen.dart
flutter_app/lib/features/organization/presentation/widgets/organisation_profile_pets.dart
flutter_app/lib/features/organization/presentation/widgets/organization_pets_section.dart
flutter_app/lib/features/pet_profile/presentation/widgets/unified_pet_tile.dart
flutter_app/lib/features/pet_profile/presentation/widgets/pet_tile_status_line.dart
flutter_app/lib/features/pet_profile/presentation/utils/pet_tile_dimensions.dart
flutter_app/test/features/organization/**
flutter_app/lib/l10n/**
.agents/plans/unified-pet-tile-c4e8.md
.agents/plans/unified-pet-tile-c4e8.snapshot.json
```

**forbidden_paths:**

```
server/**
.github/workflows/**
flutter_app/lib/features/experience/presentation/screens/guardian/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope:**

- `OrgPetListItem` → `UnifiedPetTile` (`shelter` context); remove below-tile attention `Text`
- Pass `OrgPetListEntry.attentionReason` into status resolver when no foster line
- `organisation_profile_pets`, `organization_pets_section` (org feature) → unified tile
- Creation-order sort on org grids (not attention-first)

**Exit criteria:**

- [ ] Org pet grid uses unified tile; attention folded into line 2
- [ ] No duplicate attention label below tile
- [ ] Org widget tests updated
- [ ] `./scripts/pre-push-changed.sh` green

---

### Phase 5 — Legacy pet-list surfaces, cleanup, docs

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/unified-pet-tile-cleanup-c4e8` |
| **exit_checklist** | `bdd-journey` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
flutter_app/lib/features/pet_profile/presentation/widgets/pet_card.dart
flutter_app/lib/features/pet_profile/presentation/widgets/personal_pets_section.dart
flutter_app/lib/features/pet_profile/presentation/widgets/fostered_pets_section.dart
flutter_app/lib/features/pet_profile/presentation/widgets/organization_pets_section.dart
flutter_app/lib/features/pet_profile/presentation/widgets/passed_away_pets_section.dart
flutter_app/lib/features/experience/presentation/widgets/guardian_dashboard_pet_card.dart
flutter_app/lib/features/experience/presentation/widgets/guardian_full_list_pet_card.dart
flutter_app/lib/features/experience/presentation/widgets/guardian_shell_shared_pet_card.dart
flutter_app/test/**
docs/design/plans/agathatrack-redesign-blueprint.md
docs/design/copy-tone.md
.agents/plans/unified-pet-tile-c4e8.md
.agents/plans/unified-pet-tile-c4e8.snapshot.json
```

**forbidden_paths:**

```
server/**
.github/workflows/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`, `governance-allowlist`

**Scope:**

- Migrate legacy `PetTileStrip` / `PetCard` consumers to `UnifiedPetTile` (or thin `PetCard` delegate for backward compat)
- Remove dead widgets: `GuardianDashboardPetCard`, `GuardianFullListPetCard`, no-op `GuardianShellSharedPetCard` if unused
- Update blueprint Card H (remove 4-pet cap; document unified tile + carousel)
- Fix legacy `PassedAwayPetsSection` hardcoded “Rainbow Bridge” → new l10n key (align with phase 3)
- Semantics audit: pet rail container label, tile button labels
- Optional: Playwright touch on dashboard pet rail if mapped BDD exists

**Exit criteria:**

- [ ] No production use of `GuardianDashboardPetCard` / horizontal list-row pet cards
- [ ] `PetCard` either removed or delegates to `UnifiedPetTile`
- [ ] Blueprint Card H updated
- [ ] `./scripts/pre-push-changed.sh` green

---

## Final integration PR

After phase 5 merges to `cursor/unified-pet-tile-integration-c4e8`:

1. `./scripts/pre-push.sh` on integration branch
2. One PR: integration → `main`
3. **/babysit-uat** on final merge (pre-UAT E2E gate)

## Runtime state

```yaml
autonomy: active
current_phase: 3
last_completed_phase: 2
halt_reason: null
next_action: "continue phase 3 on branch cursor/care-all-pets-unified-tile-c4e8"
artifact_ref:
  branch: cursor/care-all-pets-unified-tile-c4e8
  plan_path: .agents/plans/unified-pet-tile-c4e8.md
  plan_commit: 6e1f6d3250ef41bed4ec449460e17d89c34087b9
  snapshot_path: .agents/plans/unified-pet-tile-c4e8.snapshot.json
  snapshot_commit: 6e1f6d3250ef41bed4ec449460e17d89c34087b9
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/956"]
merge_commits: {}
debt_issue_refs: []
```

## Resolved questions (user 2026-09-03)

| # | Decision |
|---|----------|
| Q1 | EN **Rainbow bridge** / FR **Au-delà des nuages** |
| Q2 | Icon + colour on Pet Care line 2 |
| Q3 | Wings ~24px top-right, ~0.85 opacity |
| Q4 | Full scope including legacy non-embedded pet list |
| Q5 | `plan_id` `unified-pet-tile-c4e8` approved |
