---
title: Care management surfaces (Child E)
owner: Agent
audience: agent
status: active
last_updated: 2026-09-13
tags: [pet_care, care_item, ui, plan]
---

# care-management-surfaces

> **Child E of** [`pet-care-item-model`](./pet-care-item-model.md)
> **Specification:** [`docs/domains/pet_care/changes/care-item-model-delivery-plan.md`](../../docs/domains/pet_care/changes/care-item-model-delivery-plan.md) — read **§1**, **§4.4**, **§5** before starting.
> **Depends on:** Child B (primitives) and Child D (the profile section and its `View all care` link).

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-management-surfaces` |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Complete the information architecture behind the profile: **All care** as the unified pet-scoped
destination, **Care Item detail** as the single place to inspect and manage a Care Item, and
retirement of the Care Rhythms screen so recurrence is an attribute rather than a separate object.

```
Pet Profile  →  All care  →  Care Item detail  →  Edit / Add care
```

## Non-goals

- No copy or terminology changes — those are Child F, deliberately last so E2E selectors are fixed
  once. Phase work here keeps existing strings unless a string is attached to a row being deleted.
- No new domain object. `health_entries` is the Care Item; `health_occurrences` are its dates.

---

## Phase 1 — All care destination

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/care-all-care-destination-c9c6` |
| **exit_checklist** | `flutter-screen-split` |
| **merge_mode** | `auto` |

**Scope**

`flutter_app/lib/features/pet_profile/presentation/screens/pet_manage_events_screen.dart` already
unifies recurring and one-off items — it does not need rebuilding, it needs to become a coherent
destination:

- Consume Child A's grouping so All care and the profile cannot disagree.
- Adopt Child B's `CareActionRow` so rows look identical to the profile section.
- One flat, temporally ordered list of Care Items. Recurrence shown as an **attribute** on the row
  (e.g. a cadence hint), never as a separate section or tab.
- `Established` as a subtle chip; nothing for not-yet-established.
- Single "add care" entry point consistent with the profile.

**Exit criteria**

- [ ] A test asserting profile and All care place the same item in the same group (extends Child A's
      agreement test to this surface).
- [ ] No recurring-vs-one-off segmentation anywhere in the screen.
- [ ] Rows are Child B primitives — no hand-rolled equivalents.
- [ ] Empty state.
- [ ] `node scripts/check_file_size.js` passes.
- [ ] Screenshots at mobile and desktop against the Child A seed fixture.

**allowed_paths**

```
flutter_app/lib/features/pet_profile/presentation/screens/pet_manage_events_screen.dart
flutter_app/lib/features/pet_profile/presentation/widgets/all_care/**
flutter_app/test/features/pet_profile/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

---

## Phase 2 — Care Item detail

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/care-item-detail-c9c6` |
| **exit_checklist** | `flutter-screen-split` |
| **merge_mode** | `auto` |

**Scope**

One place to inspect and manage a Care Item:

- What it is (family, name, notes).
- Whether and how it recurs — recurrence as an attribute, in plain language, not schema terms.
- Its **dates** (the `health_occurrences`): upcoming and recent, with complete / skip actions.
  Section heading is **`Dates`** (spec §4.3) — this is the one string change permitted in this
  child plan because the section is new.
- `Established` badge + `Part of {Pet}'s regular care.` when established; **nothing** otherwise
  (spec §4.4). No duration, no start date, no progress.
- Edit and delete routes into the existing unified form. Deleting a recurring item must clearly
  state what happens to its dates.

**Exit criteria**

- [ ] Widget tests: one-off item; recurring item; established item; uncategorised item; item with no
      remaining dates.
- [ ] Recurrence rendered in plain language — no `frequency_interval` / `recurrence_anchor` jargon
      reaching the screen.
- [ ] Complete and skip actions work optimistically and reconcile.
- [ ] Delete confirmation states the effect on future dates.
- [ ] `Key`s for E2E; semantic labels on all controls.
- [ ] Every new file ≤ 500 lines; split rather than allowlist.
- [ ] Screenshots of the four item variants.

**allowed_paths**

```
flutter_app/lib/features/health_tracking/presentation/screens/care_item_detail/**
flutter_app/lib/core/router/app_router.dart
flutter_app/lib/l10n/**
flutter_app/test/features/health_tracking/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

> `app_router.dart` is in scope only to register the detail route. `l10n` is in scope only for the
> new `Dates` heading and the established copy — do **not** start the broader copy migration here.

---

## Phase 3 — Retire the Care Rhythms screen

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/care-retire-rhythms-screen-c9c6` |
| **exit_checklist** | `bdd-journey` |
| **merge_mode** | `auto` |

**Scope**

"Care Rhythm" stops being a user-facing object (spec §1.1, §4.2). With All care and Care Item detail
in place, the screen has no remaining job.

- Delete `flutter_app/lib/features/pet_profile/presentation/screens/pet_care_rhythms_screen.dart`
  and `.../widgets/care_rhythms/**`.
- Remove the route from `app_router.dart`; redirect the old path to All care so existing links and
  bookmarks do not 404.
- The `careRhythm*` l10n keys are retired in **Child F** with the rest of the copy work; leaving
  them orphaned for one plan is acceptable and is preferable to splitting the l10n diff.

**Exit criteria**

- [ ] `rg -i carerhythm flutter_app/lib --glob '!l10n/**'` returns nothing.
- [ ] Old route redirects to All care; a test covers the redirect.
- [ ] BDD scenarios referencing Care Rhythms updated **in this phase**;
      `node e2e/scripts/check_bdd_coverage.js --report-only` must not regress.
- [ ] Playwright specs navigating to the rhythms screen fixed **in this phase**.
- [ ] No dead imports or unreferenced widgets left behind.

**allowed_paths**

```
flutter_app/lib/features/pet_profile/presentation/screens/pet_care_rhythms_screen.dart
flutter_app/lib/features/pet_profile/presentation/widgets/care_rhythms/**
flutter_app/lib/core/router/**
flutter_app/test/bdd/features/**
e2e/**
docs/domains/pet_care/**
```

**allowed_exceptions:** `tests`, `docs`

---

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-09-13T12:40:00Z` (**placeholder** — refresh at approval) |
| **approved_until** | `2026-09-15T12:40:00Z` (**placeholder**) |
| **control_issue** | `1` (**placeholder** — run `init-control-issue care-management-surfaces`) |
| **autonomy** | `halted` — awaiting approval and Child B + D merged |

## Runtime state

```yaml
autonomy: completed
current_phase: null
last_completed_phase: 3
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: main
  plan_path: .agents/plans/care-management-surfaces.md
  plan_commit: 3e736c1daa1275888988b2a47eb4128689b3d56b
  snapshot_path: .agents/plans/care-management-surfaces.snapshot.json
  snapshot_commit: 3e736c1daa1275888988b2a47eb4128689b3d56b
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
