---
title: Care copy and terminology (Child F)
owner: Agent
audience: agent
status: active
last_updated: 2026-09-13
tags: [pet_care, terminology, l10n, plan]
---

# care-copy-and-terminology

> **Child F of** [`pet-care-item-model`](./pet-care-item-model.md)
> **Specification:** [`docs/domains/pet_care/changes/care-item-model-delivery-plan.md`](../../docs/domains/pet_care/changes/care-item-model-delivery-plan.md) — read **§4** in full before starting.
> **Depends on:** Child D and Child E (surfaces settled).

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-copy-and-terminology` |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Split the one care string that is doing two jobs, give the pet-scoped care surfaces their own
vocabulary without disturbing the global one, remove domain jargon ("occurrence") from user-facing
copy by semantic migration, and fix the navigation highlighting bug.

## Why last

Copy changes are cheap to land but break E2E selectors. Doing them after the surfaces settle means
fixing each selector once instead of twice.

## Read spec §4.0 first — it is not optional

§4.0 records the **verified** current state of D38 and the `.arb` files. Two things there invalidate
the obvious approach:

1. **`allCare` is a single key serving both scopes** — `pet_events_preview_section.dart`
   (pet-scoped) *and* `pet_care_upcoming_events_section.dart` (global dashboard). Splitting it is
   the core of this phase, not a detail.
2. **`Care actions` is unavailable** as a global screen title: D38 already uses `CARE ACTIONS` as
   the dashboard due-items eyebrow.

Also note `manageEvents` serves two scopes (pet-scoped list title **and** pet event view title ×3),
and D38's ARB key column is aspirational — `allActions` and `actionsNavLabel` do not exist.

---

## Phase 1 — Split the care vocabulary by scope; amend D38

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/care-naming-d38-c9c6` |
| **exit_checklist** | `bdd-journey` |
| **merge_mode** | `auto` |

**Scope — the canonical naming table (spec §4.1)**

| Surface | Scope | EN title | Change |
|---|---|---|---|
| Profile operational section | one pet | **`{Pet}'s care`** | `careForPet` value change |
| Section trailing link | one pet | **`View all care`** | **new** key, split off `allCare` |
| Pet-scoped list destination | one pet | **`All care`** | **new** key, replaces `manageEvents` here |
| Global dashboard "see all" link | all pets | **`All Actions`** | unchanged — keeps `allCare` |
| Global queue screen (`/pc/events`) | all pets | **`All Actions`** | reuse `allCare`, replacing `eventsNavLabel` |
| Bottom nav | all pets | **`Actions`** | unchanged |

**The global vocabulary does not change.** Titling the global screen with the same string as the
link that leads to it is more coherent than today's `Events`, needs no new key, and leaves D38
intact for every global surface.

**String keys (spec §4.2)**

| Key | Action | `en` value |
|---|---|---|
| `careForPet` | change value | `{petName}'s care` |
| `viewAllCare` | **new** | `View all care` — pet-scoped preview link only |
| `allCareTitle` | **new** | `All care` — pet-scoped list screen title |
| `allCare` | **keep key and value** | `All Actions` — global link **and** global screen title |
| `careNavLabel` | unchanged | `Actions` |
| `manageEvents` | **retire** | pet-scoped list → `allCareTitle`; pet event view → Care Item detail title (landed in Child E) |
| `eventsNavLabel` | **retire** | all three call sites are titles/headers, not nav |
| `careRhythmsTitle`, `careRhythmsSubtitle`, `careRhythmsEmpty`, `careRhythmNextDue` | **retire** | orphaned by Child E phase 3 |

**`fr`: read the existing `app_fr.arb` entry before writing.** EN and FR already diverge here — EN
says *Actions*, FR says *Soins*.

- `careForPet` → keep `Soins pour {petName}` or refine to `Soins de {petName}`.
- `viewAllCare` → `Voir tous les soins`
- `allCareTitle` → **blocked on spec open item O4.** It must **not** be `Tous les soins`, which is
  already `allCare`'s FR value for the global surface. Recommended answer:
  `Tous les soins de {petName}`.

> **Halt condition:** if no O4 decision is recorded on the control issue, halt this phase. Do not
> guess a FR string that duplicates the global one — that would ship the exact ambiguity this plan
> exists to remove.

**D38 amendment — mandatory in this same PR, and purely additive**

Add the pet-scoped rows (`{Pet}'s care`, `View all care`, `All care`) to the D38 table and correct
the ARB key column to name the **real** keys (`allCare`, `careNavLabel`, `careEyebrow`) instead of
the aspirational ones. Do not change any global row. **Do not land the strings without the
amendment** — `terminology.md` forbids ad-hoc string changes, so strings alone would leave the repo
in violation of its own governance.

**Exit criteria**

- [ ] O4 decision recorded on the control issue before any FR string is written.
- [ ] `allCare` call sites split: pet-scoped ones use `viewAllCare`, global ones still use `allCare`.
      List all four call sites in the PR body with their new key.
- [ ] D38 amended additively; global rows untouched; key column corrected to real keys.
- [ ] `en` and `fr` updated for every changed and new key; `flutter gen-l10n` output regenerated.
- [ ] Retired keys removed from `app_en.arb`, `app_fr.arb`, and all generated localisation files.
- [ ] `rg 'manageEvents|eventsNavLabel|careRhythm' flutter_app/lib` returns nothing.
- [ ] BDD scenarios asserting old titles updated **in this phase**;
      `node e2e/scripts/check_bdd_coverage.js --report-only` must not regress.
- [ ] Playwright selectors keyed to changed copy fixed **in this phase**.
- [ ] Screenshots in **both** locales of: the profile section header, the pet-scoped All care title,
      and the global queue title — proving the pet-scoped and global names are distinct in FR too.

**allowed_paths**

```
flutter_app/lib/l10n/**
docs/design/terminology.md
flutter_app/lib/features/pet_profile/presentation/**
flutter_app/lib/features/experience/presentation/screens/pet_care/**
flutter_app/lib/core/router/experience_routes.dart
flutter_app/lib/features/health_tracking/presentation/screens/pet_event_view_screen.dart
flutter_app/test/**
e2e/**
```

**allowed_exceptions:** `tests`, `docs`

---

## Phase 2 — "Occurrence" semantic copy migration

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/care-occurrence-copy-c9c6` |
| **exit_checklist** | `default` |
| **merge_mode** | `auto` |

**Scope**

`occurrence` appears in user-facing strings. It is domain jargon. Remove it by **semantic
migration, not find-and-replace** (spec §4.3):

| Context | Replacement |
|---|---|
| A single dated instance of a recurring item | *"this one"* / *"this date"* / the date itself |
| The list of instances on Care Item detail | **`Dates`** |
| A skipped/missed instance | *"skipped"* / *"missed"* |
| A completed instance | *"done"* |

Blind replacement produces sentences like "Delete this dates". **Every changed string must be read
in its rendered sentence.**

The word stays in code identifiers, table names, and route names — this phase changes copy only.

**Exit criteria**

- [ ] `rg -i occurrence flutter_app/lib/l10n/app_en.arb` returns nothing for user-facing values.
- [ ] Each changed string listed in the PR body with its **before and after full sentence**, so a
      reviewer can check the grammar without running the app.
- [ ] Screenshots of every screen region whose sentence changed.
- [ ] `fr` updated with grammatically correct equivalents, not literal word swaps.
- [ ] No identifier renames — copy only.

**allowed_paths**

```
flutter_app/lib/l10n/**
flutter_app/lib/features/health_tracking/presentation/**
flutter_app/test/**
```

**allowed_exceptions:** `tests`, `docs`

---

## Phase 3 — Navigation highlighting fix

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/care-nav-highlight-fix-c9c6` |
| **exit_checklist** | `flutter-screen-split` |
| **merge_mode** | `auto` |

**Scope**

The bottom-nav destination does not highlight correctly for all care-related routes. With the route
set changed by Child E (rhythms retired, Care Item detail added, old path redirected), fix the
active-destination derivation so every care route highlights the `Actions` destination.

Also remove the `_OperationsDeskTheme` local theme wrapper in
`flutter_app/lib/features/experience/presentation/screens/pet_care/global_events_list.dart` if it is
still present. Its aliases already resolve to the main palette, so this is not a visual change — it
is removing a maintenance trap where a future palette change would silently miss this screen. State
in the PR body that there is no visual diff.

**Exit criteria**

- [ ] A test per care route asserting the correct nav destination is active, including the redirected
      legacy rhythms path and Care Item detail.
- [ ] `_OperationsDeskTheme` gone; screenshot before/after showing no visual diff.
- [ ] `flutter analyze --no-fatal-warnings --no-fatal-infos` clean.

**allowed_paths**

```
flutter_app/lib/core/router/**
flutter_app/lib/features/experience/presentation/screens/pet_care/global_events_list.dart
flutter_app/lib/features/experience/presentation/widgets/**
flutter_app/test/core/router/**
flutter_app/test/features/experience/**
```

**allowed_exceptions:** `tests`, `docs`

---

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-09-13T12:40:00Z` (**placeholder** — refresh at approval) |
| **approved_until** | `2026-09-15T12:40:00Z` (**placeholder**) |
| **control_issue** | `1` (**placeholder** — run `init-control-issue care-copy-and-terminology`) |
| **autonomy** | `halted` — awaiting approval and Child D + E merged |

## Runtime state

```yaml
autonomy: halted
current_phase: 3
last_completed_phase: 2
halt_reason: halted
next_action: "start phase 3: checkout cursor/care-nav-highlight-fix-c9c6"
artifact_ref:
  branch: main
  plan_path: .agents/plans/care-copy-and-terminology.md
  plan_commit: 9a362b8d687911ddc7d0730711475d9508233d2b
  snapshot_path: .agents/plans/care-copy-and-terminology.snapshot.json
  snapshot_commit: 9a362b8d687911ddc7d0730711475d9508233d2b
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
