---
title: Away Planning — Delivery Plan
owner: Product / Agent
audience: both
status: active
last_updated: 2026-09-15
tags: [pet_care, care_context, delivery]
---

# Away Planning — Delivery Plan

**Canonical product behaviour:** [care-context.md](../features/care-context.md)
**Frozen decisions:** [away-planning-decisions.md](./away-planning-decisions.md)
**Execute-plan:** `.agents/plans/away-planning-v1.md`

**Status: active** — decisions frozen 2026-09-15 ([#1196](https://github.com/KanopeeKa/AgathaCheck/pull/1196) review confirmed). Verified against `main` through `fcc8a804`.

## Programme goal

Evolve `care_context` from a preview wizard into **Away Planning**: hub, plan page, per-pet carer model, derived readiness, printable handover. Context, people, projection, and handover only — scheduling stays with CSM; not Pet Sitting.

---

## Shipping gates

1. **AW-EMERGENCY** merges to `main` first — live hang-on-error defect.
2. **AW-1** before any carer UI.
3. **AW-0** before **AW-4** (carer writes on transactional handlers).
4. **AW-3** before **AW-7** (named indeterminate rows).
5. **AW-8** before **AW-6** (tile must not invent local readiness).
6. **AW-5b** flips `/pc/away` to hub only when hub content exists — **AW-2 stays additive** until then.
7. Projection corpus byte-identical through AW-3 (scheduling semantics unchanged).

Integration branch (4+ parallel phases): `cursor/away-planning-v1-integration-5176`.

---

## Phase table

| Phase | Outcome | Depends on |
|---|---|---|
| **AW-EMERGENCY** | Hang-on-error fix + regression test; repo-wide `publicError(res` grep clean | — → **`main`** |
| **AW-DOC-0** | Frozen decision log; delivery plan; `explainGap` contract; CC-4 superseded; terminology | — |
| **AW-0** | Transactions, bulk insert, batched pet ids, `dateToIsoDate`, tx mock; `timestampToIso` in `careContext` only | — |
| **AW-1** | Vet rename + personal-scope key + BDD/E2E lockstep + terminology + D34 wording | — |
| **AW-2** | **Additive** routes `/pc/away/new`, `/pc/away/:id`; `/pc/away` stays wizard; registry tests | — |
| **AW-3** | Enriched `uncertainties[]`; server routine/dated split + least-certain collapse | — |
| **AW-5a** | `scope` on list API; overlap-warning readability on read | AW-0 |
| **AW-4** | Carer migration `063` + canonical + manifest + migration test; CRUD; `carer-candidates` | AW-0 |
| **AW-8** | Readiness derivation (two facts + tile priority rule), server-side | AW-4 |
| **AW-5b** | Hub UI; flip `/pc/away`; zero-pet + passed-away empty states | AW-5a, AW-8, AW-2 |
| **AW-6** | Stateful tile; degrade-to-prompt on loading/error | AW-8 |
| **AW-7** | Plan page; no reschedule affordance | AW-3, AW-4, AW-8 |
| **AW-9** | Handover PDF; record download timestamp; surface nothing | AW-7 |
| **AW-SEED** | `away-planning.js`; exclusion-list seed test | AW-4 |
| **AW-10** | Remaining canonical docs, `away_planning.feature`, Playwright | AW-9 |
| **AW-11** | Per-pet `pet_note` + per-pet handover PDF export (D-AWAY-014, proposed) | AW-9 |

```text
AW-EMERGENCY ──> main

AW-DOC-0, AW-0, AW-1, AW-2, AW-3  (parallel)
AW-5a (parallel with AW-4 after AW-0)

AW-0 ──> AW-4 ──> AW-8 ──┬──> AW-5b ──> AW-6
AW-3 ────────────────────┼──> AW-7 ──> AW-9 ──> AW-10
AW-5a ───────────────────┘
AW-SEED (parallel after AW-4)
```

**File ownership (parallel AW-0 / AW-3):** AW-0 → `plannedAbsencesRouter.js`, `plannedAbsence.js`; AW-3 → `carePeriod*Router.js`, `lib/care/schedule/**`, new `lib/care/awayPlan/**`.

---

## AW-EMERGENCY — Hang-on-error fix

**Target:** `main` (not integration branch). Own PR, ships first.

Fix `carePeriodCoverageRouter.js` and `carePeriodProjectionRouter.js`:

```js
return res.status(500).json({ error: publicError(err, 'Failed to load …') });
```

Regression test with explicit request timeout (naive test hangs). Repo-wide grep for `publicError(res` — document in D-AWAY-013 / debt register.

**Not in this PR:** `sendPublicError` wrapper (debt).

---

## AW-DOC-0 — Plan bootstrap

Frozen decision log, this delivery plan, execute-plan file, `explainGap` contract in `care-context.md`, CC-4 superseded note, "Veterinary team" in `terminology.md`, D-AWAY-013 debt row.

---

## AW-0 — Backend hygiene

One outcome: `careContext` write paths atomic before carer schema.

| Item | Action |
|---|---|
| N+1 `loadPetIds` | Batch `WHERE planned_absence_id = ANY($1::uuid[])` |
| Transactions | Extract `withOptionalTransaction` from `careMilestoneService.js` → shared helper |
| `replaceAbsencePets` | Bulk `INSERT … unnest()` |
| `findOverlapWarnings` | `dateToIsoDate()` for DATE fields |
| Test harness | `createTransactionalMockPool` (idiom from `completeWeight.test.js`) |
| `timestampToIso()` | Add to `calendarDate.js`; use in `plannedAbsence.js` only — **debt issue** for 17 occurrences across 10 other files |

**Not AW-0:** 500-handler fix (AW-EMERGENCY). `absenceToMap` TIMESTAMPTZ fields stay `toISOString()`.

---

## AW-1 — Terminology

Eleven ARB keys × EN/FR; new `collectionFilterPersonal` key; `terminology.md`; D34 wording; widget tests; **all three** of:

- `flutter_app/test/bdd/features/guardian_dashboard.feature` scenario title
- `e2e/playwright/tests/guardian.dashboard.spec.ts` `@bdd` header + `test()` name
- `guardian-dashboard.page.ts`, `vet-list.page.ts`, `support/flutter.ts`

---

## AW-2 — Routing (additive)

Register `/pc/away/new` (wizard), `/pc/away/:id` (placeholder). **Leave `/pc/away` on wizard** until AW-5b. Add three named routes to `guardian_routes_test.dart`. Post-save navigation to plan page when `:id` exists (AW-5b).

---

## AW-3 — Projection read contract

Enrich `uncertainties[]` with `name`, `type`, `care_family`. Server-side routine/dated split + least-certain collapse in `lib/care/awayPlan/`. Rebase on latest `main` and re-run projection corpus (CSM still churning — e.g. `6fc7f776` undo fix).

---

## AW-4 — Carer schema + API

Migration `063_planned_absence_carers.sql` + `_down.sql` + `migration-manifest.json` + **`canonical.sql` regen** + static test in `server/test/migrations/`. Carer fields on `PATCH`. `GET /api/pets/:id/carer-candidates`. Carer writes bump `planned_absences.updated_at`.

---

## AW-5a — List API

Additive `scope` (`upcoming` default, `past`, `all`). Overlap warnings: **recompute on read** (or persist — implement one, document in API). Default preserves wizard invalidate shape.

---

## AW-5b — Hub UI

`plannedAbsencesListProvider` watched. Upcoming asc, past subdued desc, cancelled hidden. Flip `/pc/away` to hub. Empty states: zero-pet absence, passed-away pet on existing absence.

---

## AW-6 — Stateful tile

Three states via AW-8 derivation. Degrade to plain prompt on loading/error (not `SizedBox.shrink()`). Always → hub. Amend D34 for fourth dashboard element.

---

## AW-7 — Plan page

Header, who's caring, routine + dated + named indeterminate rows, plan details. **No reschedule affordance** (not even disabled — D-CSM-008). Per-pet coverage = N requests; **document fan-out** in `care-context.md`.

---

## AW-8 — Readiness derivation

Server module returns `{ carer_coverage, care_coverage, tile_copy }` per D-AWAY-002. Triple-output tests (15 matrix cells).

---

## AW-9 — Handover

Client PDF via existing `pdf`/`printing` + `pet_report_service.dart` pattern. `last_handover_downloaded_at` column; write on download; **no UI notice**. Verbatim-note test.

---

## AW-SEED — `away-planning.js`

After `care-schedule-fixture` in `ALL_SCENARIOS`. Coverage: carer mix, five coverage states, multi-time intersection, past/upcoming/cancelled, downloaded-then-edited (timestamp only).

**Seed test:** `ALL_SCENARIOS` keys = `SCENARIOS` keys minus explicit exclusion list (`org-v3-demo` is a **composite** of seeds already in `ALL_SCENARIOS` — do **not** add it). Idempotency: two consecutive runs.

**Not in AW-SEED:** wiring `org-v3-demo` into `ALL_SCENARIOS` (would triple-run org-clinic, rescue-hearts, connections).

---

## AW-10 — Docs + journey

`api-reference.md`, carer model doc, `away_planning.feature` + Playwright with exact `@bdd` titles.

---

## AW-11 — Per-pet note + per-pet handover export

Follow-on to AW-9, not part of original V1 scope. Migration `071` adds `planned_absence_pets.pet_note` — orthogonal to `carer_kind`/`carer_note`, usable for any carer kind. `updateAbsenceCarers` writes carer columns and `pet_note` independently, keyed on which fields are present on each `pet_carers` entry, so one never overwrites the other. New per-pet PDF export button reuses the existing client-side `AwayPlanHandoverService` pipeline via a shared `buildHandoverDocument` path; scoped to one pet's carer row and schedule, pet-scoped (not absence-aggregate) coverage copy, trip-wide `handover_note` under a distinct title, and the pet's own `pet_note`. Does not bump `last_handover_downloaded_at` — full-plan download only. Full spec: [away-planning-per-pet-handover-spec.md](./away-planning-per-pet-handover-spec.md). Decisions D-AWAY-014a/b are **Frozen** in [away-planning-decisions.md](./away-planning-decisions.md) (merged [#1266](https://github.com/KanopeeKa/AgathaCheck/pull/1266)).

---

## Explicitly out of scope

Reschedule/move affordances. Per-item carer assignment. Pet Sitting. Public share links. CIM changes. Holiday mode. Mandatory plan completion before save. §3.8 absence pointer column.

---

## Related

- [away-planning-decisions.md](./away-planning-decisions.md)
- [care-through-change-delivery-plan.md](./care-through-change-delivery-plan.md)
