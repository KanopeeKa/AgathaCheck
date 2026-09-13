---
title: Care presentation primitives (Child B)
owner: Agent
audience: agent
status: active
last_updated: 2026-09-13
tags: [pet_care, design_system, widgets, plan]
---

# care-presentation-primitives

> **Child B of** [`pet-care-item-model`](./pet-care-item-model.md)
> **Specification:** [`docs/domains/pet_care/changes/care-item-model-delivery-plan.md`](../../docs/domains/pet_care/changes/care-item-model-delivery-plan.md) — read **§5** and **§10** before starting.

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-presentation-primitives` |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Build the shared component and token layer for the four semantic roles — **Attention, Action,
Insight, Destination** — plus the trend sparkline, and fix the pre-existing status-colour contrast
defect. Screens consume these; they must not hand-roll equivalents.

## Why this is before screen work

Spec §5: the four treatments must exist as shared primitives before three different screens adopt
them, or each screen invents its own and the visual language drifts immediately. This layer is the
mechanism that makes "distinct visual treatment by purpose" actually hold.

## Non-goals

- No screen composition. `pet_detail_screen.dart`, `pet_manage_events_screen.dart` and the care
  rhythms screen are **not** touched here.
- No new copy. Primitives take strings from the caller (l10n at the call site) so they stay
  copy-agnostic.
- No new colour literals. Everything resolves from `AppColorTokens` / `ColorScheme` /
  `ExperienceColors`.

---

## Phase 1 — Accessibility fix for care status treatment

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/care-primitives-a11y-status-c9c6` |
| **exit_checklist** | `flutter-screen-split` |
| **merge_mode** | `auto` |

**Scope**

`healthEntryStatusColor()` in
`flutter_app/lib/features/health_tracking/presentation/widgets/health_entry_status.dart` returns the
warning colour for small text on a light surface. That combination **fails contrast**. Fix it before
the new primitives inherit it.

Apply spec §10:

1. Status conveyed by **text + icon**, never colour alone.
2. Where colour is needed: semantic **foreground** for glyph/text on a **subtle semantic
   background** — do not paint small text in the raw semantic colour.

**Exit criteria**

- [ ] Contrast ratio for every status treatment meets the threshold in `docs/design/system.md`;
      record the measured ratios in the PR body.
- [ ] Every status renders an icon alongside its text.
- [ ] Existing call sites of `healthEntryStatusColor` updated; no caller left painting raw semantic
      colour onto small text.
- [ ] Widget test covering each status variant.
- [ ] Before/after screenshots in the PR body.

**allowed_paths**

```
flutter_app/lib/features/health_tracking/presentation/widgets/health_entry_status.dart
flutter_app/lib/features/health_tracking/presentation/widgets/care_event_status_line.dart
flutter_app/test/features/health_tracking/**
```

**allowed_exceptions:** `tests`, `docs`

> This is a standalone bug fix with its own verifiable outcome. It ships first so the primitives in
> phase 2 are built on a correct treatment rather than needing a follow-up sweep.

---

## Phase 2 — The four semantic-role primitives and shared tokens

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/care-primitives-roles-c9c6` |
| **exit_checklist** | `flutter-screen-split` |
| **merge_mode** | `auto` |

**Scope**

New directory: `flutter_app/lib/features/pet_care/presentation/widgets/care_surface/`

| Widget | Role | Visual rules (spec §5) |
|---|---|---|
| `CareAttentionCallout` | Attention | Semantic foreground text/icon on **subtle** semantic background. Never a saturated banner. Compact height. At most one per screen region (the caller enforces the count). |
| `CareActionRow` | Action | Leading family icon, title, temporal subtitle, trailing primary affordance. Neutral surface. Status by text + icon. |
| `CareInsightTile` | Insight | Low-emphasis card, no primary affordance, whole tile tappable to its destination. Hosts `CareTrendSparkline`. |
| `CareDestinationRow` | Destination | Label + chevron. No card chrome. No counts unless the count is the point. |
| `CareTrendSparkline` | — | Small trend line. **Must render a meaningful empty/insufficient-data state, not a flat line.** |
| `CareSurfaceTokens` | — | Shared spacing/radius/emphasis constants resolved from existing tokens. |

**Exit criteria**

- [ ] Widget test per primitive, **including** the empty and insufficient-data states.
- [ ] Every interactive primitive exposes a `Key` for E2E and a semantic label for a11y
      (`accessibility.mdc`).
- [ ] Zero new raw colour literals — evidence by `rg` for hex literals in the new directory.
- [ ] Every new file ≤ 500 lines (`node scripts/check_file_size.js`). **Split, do not allowlist** —
      allowlisting a new file is an escalation trigger.
- [ ] Golden or screenshot evidence of all four roles rendered side by side, so the "distinct
      treatment by purpose" claim is reviewable.
- [ ] Primitives take no `AppLocalizations` dependency — confirm by inspection.

**allowed_paths**

```
flutter_app/lib/features/pet_care/presentation/widgets/care_surface/**
flutter_app/test/features/pet_care/presentation/widgets/care_surface/**
docs/design/system.md
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

> `docs/design/system.md` is included so the four roles can be documented as part of the design
> system in the same PR that creates them. Document them — a component layer nobody knows about
> gets bypassed.

---

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-09-13T12:40:00Z` (**placeholder** — refresh at approval) |
| **approved_until** | `2026-09-15T12:40:00Z` (**placeholder**) |
| **control_issue** | `1` (**placeholder** — run `init-control-issue care-presentation-primitives`) |
| **autonomy** | `halted` — awaiting approval |

## Runtime state

```yaml
autonomy: halted
current_phase: null
last_completed_phase: null
halt_reason: "awaiting approval"
next_action: "bootstrap control issue, refresh approval window, set autonomy active"
artifact_ref:
  branch: cursor/care-item-model-plans-c9c6
  plan_path: .agents/plans/care-presentation-primitives.md
  plan_commit: null
  snapshot_path: .agents/plans/care-presentation-primitives.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
