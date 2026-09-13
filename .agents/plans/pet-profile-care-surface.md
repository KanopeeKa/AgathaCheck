---
title: Pet Profile care surface (Child D)
owner: Agent
audience: agent
status: active
last_updated: 2026-09-13
tags: [pet_care, pet_profile, ui, plan]
---

# pet-profile-care-surface

> **Child D of** [`pet-care-item-model`](./pet-care-item-model.md)
> **Specification:** [`docs/domains/pet_care/changes/care-item-model-delivery-plan.md`](../../docs/domains/pet_care/changes/care-item-model-delivery-plan.md) — read **§8**, **§9**, **§10** before starting.
> **Depends on:** Child A (one status derivation) **and** Child B (the four primitives). Do not start before both are merged.

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `pet-profile-care-surface` |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Make the Pet Profile read as a concise picture of the pet's current care situation: a temporally
grouped **`{Pet}'s care`** section as the operational centre, attention states derived rather than
carded, and weight / health issues / timeline demoted to insight and destination treatments.

## Target composition (spec §9 — authoritative)

| # | Region | Role | Notes |
|---|---|---|---|
| 1 | Pet identity header | — | Unchanged |
| 2 | Completeness prompt | Attention (single, compact) | Collapse today's multiple prompts into **one**. Dismissible. |
| 3 | Safeguard slot | Attention | At most one, only when active (§8) |
| 4 | **`{Pet}'s care`** | Action | Temporal groups; `View all care` trailing link; **operational centre** |
| 5 | Suggestion / milestone slot | Contextual card | At most one (§8) |
| 6 | Weight | Insight | Compact tile + `CareTrendSparkline` |
| 7 | **Health & history** | Destination | Quiet group: Health issues, Timeline. Minimal rows, no cards. |

**Removed from the profile:** the standalone "Time to follow up" card (becomes a state inside #4)
and the Care Rhythms navigation row.

**Non-negotiable:** at no breakpoint may anything outrank `{Pet}'s care` visually.

## Care Intelligence placement (spec §8)

Arbitration **already exists** — `flutter_app/lib/features/pet_care/presentation/pet_care_presentation_policy.dart`
(`profileSafeguard` / `profileSuggestion` / `profileMilestoneMoment`) already guarantees at most one
card. Do not rebuild it. What changes is treatment by kind:

| Kind | Treatment | Placement |
|---|---|---|
| Safeguard (something may be wrong) | `CareAttentionCallout`, compact | **Above** `{Pet}'s care` |
| Suggestion / milestone moment | One contextual card | **Below** `{Pet}'s care` |

A safeguard buried under the care list is a safety problem; a suggestion above it competes with the
carer's work.

## Why two phases

`pet_detail_screen.dart` is already near the 500-line cap and its widget tree order is load-bearing
for existing tests. Landing the new section and the recomposition together makes the diff
unreviewable and the file-size gate unmeetable. Phase 1 builds the section in isolation with its own
tests; phase 2 adopts it and demotes everything else.

---

## Phase 1 — The `{Pet}'s care` section

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/pet-profile-buddys-care-section-c9c6` |
| **exit_checklist** | `flutter-screen-split` |
| **merge_mode** | `auto` |

**Scope**

Build the section widget under
`flutter_app/lib/features/pet_profile/presentation/widgets/pet_care_section/`, consuming Child A's
grouping provider and Child B's `CareActionRow` / `CareAttentionCallout`.

- Temporal groups only: needs attention / today / upcoming. **Never** grouped by type or by
  recurring-vs-one-off (explicitly rejected, spec §13).
- One-off and recurring items sit together in the same group — that is the single-Care-Item mental
  model made visible.
- `Established` shown as a subtle chip. **Nothing** shown for not-yet-established: no "building
  pattern", no counts, no streaks (spec §4.4, §13).
- Trailing `View all care` link to the pet-scoped All-care destination.
- Empty state when the pet has no care items.
- The old `pet_events_preview_section.dart` is superseded; phase 1 may leave it in place and phase 2
  removes its usage, or phase 1 may replace its internals — either is acceptable, but the section
  must be independently testable.

**Exit criteria**

- [ ] Widget tests: each group renders; groups with no items are omitted entirely (not shown empty);
      overall empty state; `Established` chip; an uncategorised item still renders and is
      completable.
- [ ] Optimistic completion moves an item between groups immediately.
- [ ] Consumes Child B primitives — **no** hand-rolled row/callout. Verify by inspection and say so
      in the PR body.
- [ ] Status by text + icon, never colour alone (spec §10).
- [ ] `Key`s on interactive elements for E2E.
- [ ] Every new file ≤ 500 lines; split rather than allowlist.
- [ ] Screenshots at mobile and desktop widths, against the Child A seed fixture.

**allowed_paths**

```
flutter_app/lib/features/pet_profile/presentation/widgets/pet_care_section/**
flutter_app/test/features/pet_profile/presentation/widgets/pet_care_section/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

---

## Phase 2 — Pet Profile recomposition

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/pet-profile-recomposition-c9c6` |
| **exit_checklist** | `bdd-journey` |
| **merge_mode** | `auto` |

**Scope**

Recompose `pet_detail_screen.dart` to the spec §9 order:

- Adopt the phase 1 section as region 4.
- Split the safeguard slot above / suggestion-milestone slot below (§8).
- Collapse completeness prompts into one compact attention treatment.
- Weight → `CareInsightTile` + `CareTrendSparkline`, tapping through to weight detail.
- Health issues + Timeline → `CareDestinationRow`s in a quiet **Health & history** group.
- Delete the standalone "Time to follow up" card (`care_status_summary_card.dart`) and the Care
  Rhythms row from `pet_profile_section_nav.dart`.
- Responsive: mobile single column in spec order; desktop may move insight + destination to a
  secondary column while `{Pet}'s care` keeps the primary. Tablet placement of the weight tile is
  open item **O3** — decide with a real screenshot and record the decision in the PR body.

**Exit criteria**

- [ ] Existing Pet Profile widget tests updated, not deleted, where a row moved rather than
      disappeared.
- [ ] BDD: Gherkin scenarios asserting the retired rows / old section title updated **in this
      phase**. `node e2e/scripts/check_bdd_coverage.js --report-only` must not regress.
- [ ] Playwright selectors keyed to retired copy or rows fixed **in this phase** — not deferred.
- [ ] `node scripts/check_file_size.js` passes; `pet_detail_screen.dart` ≤ 500 lines.
- [ ] Screenshots at mobile, tablet, and desktop widths proving `{Pet}'s care` outranks everything
      at every breakpoint.
- [ ] Safeguard-above / suggestion-below verified with a seeded safeguard **and** a seeded
      suggestion — screenshot both.
- [ ] Semantic labels on all new interactive controls.

**allowed_paths**

```
flutter_app/lib/features/pet_profile/presentation/screens/pet_detail_screen.dart
flutter_app/lib/features/pet_profile/presentation/screens/widgets/**
flutter_app/lib/features/pet_profile/presentation/widgets/pet_detail/**
flutter_app/lib/features/pet_profile/presentation/widgets/care_status_summary_card.dart
flutter_app/lib/features/care_intelligence/presentation/widgets/**
flutter_app/test/features/pet_profile/**
flutter_app/test/bdd/features/**
e2e/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

> Note the deliberate overlap-free split: phase 1 owns `widgets/pet_care_section/**`, phase 2 owns
> the screen and the legacy widget directories. Do not edit the phase 1 directory from phase 2.

---

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-09-13T12:40:00Z` (**placeholder** — refresh at approval) |
| **approved_until** | `2026-09-15T12:40:00Z` (**placeholder**) |
| **control_issue** | `1` (**placeholder** — run `init-control-issue pet-profile-care-surface`) |
| **autonomy** | `halted` — awaiting approval and Child A + B merged |

## Runtime state

```yaml
autonomy: halted
current_phase: null
last_completed_phase: null
halt_reason: "awaiting approval; blocked on care-status-consolidation and care-presentation-primitives"
next_action: "confirm Child A and Child B merged, then bootstrap control issue"
artifact_ref:
  branch: cursor/care-item-model-plans-c9c6
  plan_path: .agents/plans/pet-profile-care-surface.md
  plan_commit: null
  snapshot_path: .agents/plans/pet-profile-care-surface.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
