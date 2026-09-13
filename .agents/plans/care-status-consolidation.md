---
title: Care status consolidation (Child A)
owner: Agent
audience: agent
status: active
last_updated: 2026-09-13
tags: [pet_care, care_item, status, plan]
---

# care-status-consolidation

> **Child A of** [`pet-care-item-model`](./pet-care-item-model.md)
> **Specification:** [`docs/domains/pet_care/changes/care-item-model-delivery-plan.md`](../../docs/domains/pet_care/changes/care-item-model-delivery-plan.md) — read **§3** and **§6** before starting.

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-status-consolidation` |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Produce **one** care-status derivation that yields the temporal grouping
(`needsAttention` / `today` / `upcoming`) consumed by the Pet Profile, the All-care destination, and
the Pet Care dashboard — replacing the four competing derivations — and land the shared seed fixture
every later phase reviews against.

## Why this is first

Spec §3: status/urgency is derived in at least four places with three vocabularies:

| Derivation | File |
|---|---|
| Pet-level `CareStatus` | `flutter_app/lib/features/pet_profile/domain/services/care_status_service.dart` |
| Dashboard urgency (`petCareTodayCareUrgency`) | `flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_dashboard_helpers.dart` |
| `OccurrenceZone` | `flutter_app/lib/features/health_tracking/domain/occurrence_scheduling.dart` |
| Server open-occurrence shaping | `server/lib/occurrenceScheduling.js` (`listOpenOccurrences`) |

Grouping Care Items temporally on the profile means the profile **must** agree with the list and the
dashboard. Building the new section on four derivations guarantees "needs attention" on the profile
contradicting "overdue" in All care. Consolidate first.

## Contract (spec §6 — restated, authoritative)

1. A single pet-scoped service produces the temporal grouping:
   - `needsAttention` — overdue, **or** an attention state such as *time to follow up*
   - `today` — due today, not yet done
   - `upcoming` — due after today, within the caller's horizon
2. `CareStatus` (`allSet` / `worthACheck` / `timeToFollowUp`) survives **only** as the pet-level
   summary and must be **computed from** the grouping, not derived in parallel.
3. `petCareTodayCareUrgency` and `OccurrenceZone` are re-expressed in terms of the grouping or
   deleted. Leaving them as independent derivations **fails the phase**.
4. The server's `listOpenOccurrences` shaping is the **authority for dates**. The client derives
   grouping from it and must not re-implement due-date maths. Calendar dates stay `YYYY-MM-DD` on
   the wire.
5. Optimistic completion must move an item out of its group immediately and reconcile on
   confirmation. Current behaviour must not regress.

## Non-goals

- No visual change. No copy change. No new widget. Screens keep rendering what they render today,
  just from the consolidated source.
- No change to `care_family` (that is Child C).
- If a screen's rendering *must* shift to adopt the new provider shape, keep it to the minimum
  needed to compile and pass existing tests.

---

## Phase 1 — Consolidated care-status service and providers

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/care-status-consolidation-service-c9c6` |
| **exit_checklist** | `flutter-screen-split` |
| **merge_mode** | `auto` |

**Scope**

- Introduce the temporal-grouping service + Riverpod providers under
  `flutter_app/lib/features/pet_care/domain/` and `.../pet_care/presentation/providers/`.
- Re-point `care_status_service.dart` so `CareStatus` is computed from the grouping.
- Re-express or delete `petCareTodayCareUrgency` and `OccurrenceZone`.
- Update the call sites that consume the retired derivations so the app compiles and existing tests
  pass with **unchanged rendering**.

**Exit criteria (in addition to the `flutter-screen-split` checklist)**

- [ ] A provider test asserts the **same** care item lands in the **same** group when read through
      the profile provider, the All-care provider, and the dashboard provider (spec §6 exit
      evidence). This test is the point of the phase — do not skip it.
- [ ] No remaining independent due-date/urgency derivation in `flutter_app/lib` — evidence by
      `rg` output in the PR body.
- [ ] Optimistic-completion test still green (item leaves its group immediately, reconciles after).
- [ ] `flutter analyze --no-fatal-warnings --no-fatal-infos` clean.
- [ ] No visual diff — state this explicitly in the PR body.

**allowed_paths**

```
flutter_app/lib/features/pet_care/domain/**
flutter_app/lib/features/pet_care/presentation/providers/**
flutter_app/lib/features/pet_profile/domain/**
flutter_app/lib/features/health_tracking/domain/**
flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_dashboard_helpers.dart
flutter_app/test/features/pet_care/**
flutter_app/test/features/pet_profile/**
flutter_app/test/features/health_tracking/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

> The consuming widgets under `features/*/presentation/widgets/**` are **not** in `allowed_paths`.
> If a consumer must change to compile, that is a `file-split`-adjacent edit — halt and request a
> path amendment rather than silently widening scope. Keeping presentation out of this phase is
> deliberate: it is what makes the PR reviewable as "no visual change".

---

## Phase 2 — Shared seed fixture

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/care-status-consolidation-seed-c9c6` |
| **exit_checklist** | `single-backend-route` |
| **merge_mode** | `auto` |

**Scope**

Land the fixture recipe from spec §11 into `server/scripts/seed.js` (extend, do not replace) so
every later phase and every reviewer sees the same profile.

One pet with:

| Care item | Demonstrates |
|---|---|
| Recurring, overdue | `needsAttention` |
| Recurring, due today, not done | `today` |
| Recurring, due today, already done | done-state rendering |
| Recurring, due later this week | `upcoming` |
| One-off, due today | one-off and recurring co-existing in one group |
| Recurring, uncategorised `care_family` | uncategorised still works |
| Weight monitoring that genuinely **establishes** (see below) | `Established` badge + real sparkline |
| One open health issue | Health & history is non-empty |

Plus a second, near-empty pet so empty states are reviewable.

**The weight item is the only route to the `Established` state.** `supportsEstablishment` is true
for `weight_monitoring` alone (`server/lib/care/capabilities.js` — exactly one match in the
capability matrix), so do not expect a generic recurring item to establish. From
`server/lib/care/progression/weightEstablishmentPolicy.js`, the `high` cadence band requires:

| Requirement | Value |
|---|---|
| Interval (to land in the `high` band) | **≤ 14 days** → use weekly recurrence |
| `minCompletedOccurrences` | **4** |
| `minSpanDays` | **21** |
| `minMeasurements` | **3** |

Miss any one of these and no later phase can review the `Established` treatment.

**Exit criteria**

- [ ] `node scripts/migrate.js up` then the seed runs clean against a fresh `agatha_db`.
- [ ] No `gen_random_uuid()` in SQL — UUIDs generated in code (`AGENTS.md`).
- [ ] The seeded weight item **actually reports established** — assert it, do not eyeball it.
- [ ] Seeded dates are relative to run date, not hard-coded, so the fixture stays valid.
- [ ] PR body includes the seed output and a screenshot of the resulting profile as a **baseline**
      for Child D to diff against.

**allowed_paths**

```
server/scripts/seed.js
server/test/**
docs/domains/pet_care/changes/care-item-model-delivery-plan.md
```

**allowed_exceptions:** `tests`, `docs`

---

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-09-13T12:40:00Z` (**placeholder** — refresh at approval) |
| **approved_until** | `2026-09-15T12:40:00Z` (**placeholder**) |
| **control_issue** | `1` (**placeholder** — run `init-control-issue care-status-consolidation`) |
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
  plan_path: .agents/plans/care-status-consolidation.md
  plan_commit: null
  snapshot_path: .agents/plans/care-status-consolidation.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
