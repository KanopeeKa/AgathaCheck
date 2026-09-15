---
title: Away Planning — Delivery Plan
owner: Product / Agent
audience: both
status: draft
last_updated: 2026-09-15
tags: [pet_care, care_context, delivery]
---

# Away Planning — Delivery Plan

**Canonical product behaviour:** [care-context.md](../features/care-context.md)
**Proposed decisions:** [away-planning-decisions.md](./away-planning-decisions.md)
**Execute-plan:** `.agents/plans/away-planning-v1.md`

**Status: draft, awaiting human confirmation.** No phase may start and no execute-plan snapshot may be authorised until the decisions in the decision log are marked `Frozen`. Verified against `main` at `11fc85b3` (Care Schedule Management V1 integration).

## Programme goal

Evolve `care_context` from a pull-only preview wizard into **Away Planning**: a hub, a per-absence plan page, a per-pet carer model, and a printable handover document. Away Planning owns **context, people, projection and handover**. It does not own scheduling — Care Schedule Management does — and it is not Pet Sitting.

---

## Premises that changed since the brief was written

| Brief assumption | Reality on `main` |
|---|---|
| CSM's `explainGap` "doesn't exist yet" | Exists: `server/lib/care/schedule/explainGap.js` (CSM-13, merged in [#1193](https://github.com/KanopeeKa/AgathaCheck/pull/1193)) |
| Projection lives in `carePeriodProjection.js` | Now a thin re-export of `server/lib/care/schedule/projectSchedule.js`; `carePeriodProjection.js` is a compatibility shim |
| Seeds have no multi-time `schedule_times` coverage | `server/db/seeds/scenarios/care-schedule-fixture.js` added multi-slot coverage; the gap is now **absence** coverage only |
| `absenceToMap` date coercion needs `dateToIsoDate` | Calendar fields already use it; the remaining `toISOString()` calls are on **timestamps**, where truncating to a date would be a breaking API change |

---

## Shipping gates

1. **AW-1 (terminology rename) merges before any carer UI.** Surfacing carers while "Care team" still means vets ships the collision to users.
2. **AW-2 (routing restructure) merges before any hub or plan-page content.** Otherwise hub work and route work collide in the same files.
3. **AW-3 (`uncertainties[]` enrichment) merges before the plan page.** Per D-AWAY-007, a plan page built on `items` alone omits indeterminate care.
4. **AW-0 (backend hygiene) merges before the carer schema.** Adding carer writes to untransactional multi-statement handlers compounds the defect.
5. Care-period projection corpus (`server/test/careContext/carePeriodProjectionCorpus.js`) stays byte-identical throughout. Away Planning changes no scheduling semantics.

---

## Implementation sequence

```text
AW-0    Backend hygiene: 500-handler fix, transactions, batched pet-ids, date helper
AW-1    Terminology: "Care team" (vets) -> "Veterinary team"      [standalone, no deps]
AW-2    Routing: hub at /pc/away, wizard to /pc/away/new, detail /pc/away/:id
AW-3    Projection read contract: enrich uncertainties, server-side routine collapse
AW-4    Carer schema + CRUD API
AW-5    Hub content (list, upcoming/past, cancelled hidden)
AW-6    Stateful dashboard tile
AW-7    Plan page: header, who's caring, routine + dated care, plan details
AW-8    Readiness derivation + reassurance copy
AW-9    Handover document (PDF/print) + "changed since download"
AW-SEED Seed scenario: away-planning.js               [parallel after AW-4]
AW-10   Canonical docs + BDD/E2E journey
```

Dependency order:

```text
AW-0 ──┬─> AW-4 ──┬─> AW-5 ──> AW-6
       │          ├─> AW-7 ──> AW-8 ──> AW-9 ──> AW-10
AW-1 ──┤          └─> AW-SEED
AW-2 ──┤
AW-3 ──┘
```

AW-0, AW-1, AW-2 and AW-3 are mutually independent and may run in parallel. Integration branch required (4+ phases): `cursor/away-planning-v1-integration-5176`.

---

## AW-0 — Backend hygiene in `careContext`

One verifiable outcome: **the existing `careContext` routers are correct and atomic before carer writes land on them.**

| Defect | Fix |
|---|---|
| `publicError(res, err, msg)` called with the wrong signature in both read routers — the return value is discarded and **no response is ever sent**, so a DB failure hangs the request | `res.status(500).json({ error: publicError(err, 'Failed to load …') })`, matching `plannedAbsencesRouter.js` |
| N+1 `loadPetIds` per row in `GET /` | One batched `WHERE planned_absence_id = ANY($1::uuid[])`, grouped in JS |
| `POST /` and `PATCH /:id` run insert/update + `replaceAbsencePets` unwrapped; `PATCH` leaves the absence with zero pets between `DELETE` and the insert loop | Explicit transaction via a shared helper extracted from `withOptionalTransaction` in `server/lib/care/progression/careMilestoneService.js` |
| `replaceAbsencePets` inserts in a loop | Single multi-row `INSERT … SELECT * FROM unnest($2::uuid[])` |
| `findOverlapWarnings` hand-rolls `toISOString().slice(0, 10)` on two `DATE` fields | `dateToIsoDate()` from `server/lib/calendarDate.js` |

**Test-harness prerequisite:** `createMockPool` (`server/test/pets/helpers.js`) exposes no `connect()`. Transactions must either use the optional-transaction helper or the harness must gain a transaction-capable mock. AW-0 adds the latter — a `createTransactionalMockPool` following the idiom already in `server/test/healthEntries/completeWeight.test.js` — so the forced-failure rollback case can actually be asserted rather than assumed.

**Exit criteria:**

- [ ] Both read routers return `500` with a redacted body on DB failure; regression test asserts a response arrives (today the request times out)
- [ ] `GET /` issues exactly two queries regardless of absence count; test asserts the query count
- [ ] `POST` / `PATCH` emit `BEGIN` … `COMMIT`; forced mid-write failure emits `ROLLBACK` and leaves no partial state
- [ ] No `toISOString().slice(0, 10)` remains under `server/routes/careContext/` or `server/lib/care/plannedAbsence.js`
- [ ] Overlap-warning behaviour unchanged (regression)
- [ ] `carePeriodProjectionCorpus.js` byte-identical

**Explicitly not in AW-0:** converting `absenceToMap`'s `created_at` / `updated_at` / `cancelled_at` to `dateToIsoDate()`. Those are `TIMESTAMPTZ`; `toISOString()` is correct for them and truncating to `YYYY-MM-DD` would drop time-of-day from the API. If the three inline variants are worth unifying, the fix is a shared `timestampToIso()` helper — tracked as a debt issue, not smuggled into this PR.

---

## AW-1 — Terminology: "Care team" → "Veterinary team"

Standalone, no dependencies, merges first or alongside AW-0. Per D-AWAY-012.

Scope: ~11 ARB keys in `app_en.arb` / `app_fr.arb` (`myVets`, `careTeamEyebrow`, `careTeam`, `allCareTeams`, `careTeamCaringForPets`, `careTeamPetsCaredFor`, `careTeamNoLinkedPets`, `careTeamOptions`, `editCareTeam`, `careTeamClinicSubtitle`, `careTeamClinicType`), their Dart call sites in `features/vet/` and `features/experience/`, widget tests asserting the literals, and the E2E locators in `e2e/playwright/pages/guardian-dashboard.page.ts`, `vet-list.page.ts` and `support/flutter.ts`.

**Exit criteria:**

- [ ] EN "Veterinary team" / FR "Équipe vétérinaire" on every vet surface
- [ ] `org_context_collection_filter.dart` uses a new personal-scope key, not `myVets` (D-AWAY-012)
- [ ] `docs/design/terminology.md` records the split; "care team" reserved for carers
- [ ] BDD feature + Playwright locators updated together; `check_bdd_coverage.js` no worse
- [ ] Widget names (`CareTeamCard`, `CareTeamIdentityCard`) renamed or an explicit debt issue filed — not silently left mismatched

---

## AW-2 — Routing restructure

Standalone, no dependencies. Foundational: hub and plan-page PRs would otherwise all touch the router.

| Route | Name | Screen |
|---|---|---|
| `/pc/away` | `petCareAway` | hub (placeholder in this PR) |
| `/pc/away/new` | `petCareAwayNew` | `PlannedAbsenceFlowScreen` (unchanged) |
| `/pc/away/:id` | `petCareAwayDetail` | plan page (placeholder in this PR) |

Follows the nested-child idiom already used by `/pc/vets` in `flutter_app/lib/core/router/vet_routes.dart`. `pet_care_primary_destinations.dart` already treats `/pc/away/...` as in-workspace, so the nav shell needs no change.

**Exit criteria:**

- [ ] Three routes registered; `/pc/away` no longer opens the wizard directly
- [ ] `guardian_routes_test.dart` covers all three named routes (it currently covers none of `/pc/away`)
- [ ] `PlannedAbsenceEntryTile` navigates to `/pc/away`, and the wizard's post-save `context.pop()` is replaced by navigation to the saved absence's plan page
- [ ] Deprecation note recorded for direct `/pc/away` → wizard entry

---

## AW-3 — Projection read contract for the plan page

Server-side, no UI. Two additive changes to what the plan page and the PDF read.

1. **Enrich `uncertainties[]`** from `{ health_entry_id, reason }` to include `name`, `type` and `care_family`, so an indeterminate item can be named (D-AWAY-007). Additive; existing consumers unaffected.
2. **Server-side routine/dated split and collapse**, adjacent to the projector, returning routine rows with a `certainty` equal to the minimum of their constituents and a `constituent_count` (D-AWAY-006). Implemented server-side so plan page and PDF cannot diverge.

**Exit criteria:**

- [ ] `uncertainties[]` enriched; projection corpus updated with intent, `items[]` byte-identical
- [ ] Collapse unit tests: all-certain → certain; one conditional among six certain → conditional; materialised + projected mix → conditional
- [ ] Multi-per-day entry (`schedule_times: ['08:00','20:00']`) collapses per day without losing the slot count
- [ ] Non-daily frequency intersecting a window stays a dated row, not a routine row

---

## AW-4 — Carer schema + CRUD API

Migration `063_planned_absence_carers.sql` (+ `_down.sql`), manifest entry, regenerated `db/schema/canonical.sql`, static migration test following `server/test/migrations/062_care_schedule_management.test.js`. Columns and constraints per D-AWAY-003; authorization per D-AWAY-005.

API: carer assignment on the existing `PATCH /api/planned-absences/:id` (additive, per-pet array) rather than a new sub-resource — one round trip, one transaction, and the handler is already transactional after AW-0.

**Exit criteria:**

- [ ] Migration up/down; manifest + canonical regenerated; `check-migration-manifest.js` and `check-schema-equivalence.sh` green
- [ ] `shared_user` write rejected with `403` unless the target holds `pet_access` on that pet in `COLLABORATOR_ROLES`
- [ ] `note_only` write stores name + note and creates **no** `pet_access` row, no share link, no notification (asserted)
- [ ] Per-pet assignment across pets in one absence; partial assignment (one set, one unset) valid
- [ ] Carer writes participate in the same transaction as date/pet writes
- [ ] Carer changes bump `planned_absences.updated_at` (D-AWAY-009 option 1)

---

## AW-5 — Hub content

`GET /api/planned-absences` currently filters `ends_on >= today`, so **past absences are unreachable** — the hub needs an additive `scope` parameter (`upcoming` default, `past`, `all`). Cancelled absences stay excluded from the default view.

**Exit criteria:**

- [ ] Hub lists upcoming (ascending), past (descending, collapsed/subdued), cancelled hidden
- [ ] `plannedAbsencesListProvider` is `watch()`ed — today it is only ever `invalidate()`d
- [ ] Carer summary line, item count, "View plan" per row; "+ Plan time away" CTA → `/pc/away/new`
- [ ] Default `scope` preserves the existing response shape for the wizard's invalidate path

---

## AW-6 — Stateful dashboard tile

Three states per §3.1: no absence, one upcoming with a ready plan, one upcoming with planning outstanding. No percentage, no checklist. Always taps through to the hub. Follows the `PetCareDashboardContextualSlotSection` provider-driven idiom.

**Exit criteria:**

- [ ] All three states render from the list provider; loading and error collapse to the plain prompt rather than an error card
- [ ] Tile never routes directly into the wizard
- [ ] Multi-absence case renders the soonest upcoming only

---

## AW-7 — Plan page

Sections per §3.4: header (dates, pets, days away) → who's caring → care expected while away (routine collapsed, dated per date with certainty labels, **indeterminate rows present** per D-AWAY-007) → handover → plan details.

Coverage and projection are per pet (`GET /api/pets/:petId/care-period-coverage`), so a two-pet absence issues two requests. Acceptable for V1; a batched endpoint is a follow-up, not a prerequisite.

**Exit criteria:**

- [ ] Routine collapse renders least-certain state (the case most likely to be silently wrong)
- [ ] `~` prefix and "Expected based on the current schedule" on conditional rows, dated and collapsed alike
- [ ] Indeterminate entries render as named rows, not omissions
- [ ] Carer display distinguishes `shared_user` from `note_only` with no implied access
- [ ] No "move this occurrence" affordance anywhere, not even disabled (CSM owns rescheduling; D-CSM-008)
- [ ] Screen files stay under 500 lines (`check_file_size.js`)

---

## AW-8 — Readiness derivation

Server-derived, per D-AWAY-001 and D-AWAY-002. Reuses `evaluateCarePeriodCoverage()`; adds no coverage vocabulary.

**Exit criteria:**

- [ ] Matrix test: (carer set / partially set / unset) × five `coverage_state` values → expected derived readiness, 15 cases
- [ ] `nothing_scheduled` never renders as "everything looks covered" (D-AWAY-002)
- [ ] Grep-level assertion that no readiness value is persisted on `planned_absences`
- [ ] Dashboard tile, plan page and PDF read the same derivation

---

## AW-9 — Handover document

Client-side PDF via the existing `pdf` + `printing` packages and `pdf_saver_web.dart` / `pdf_saver_mobile.dart` — the same path as `pet_report_service.dart`. No server-side PDF dependency.

Structure per §3.7: care contact → per-pet daily/dated care with `~` certainty markers → verbatim handover note (D-AWAY-008) → veterinary team contact → generated-date stamp. Designed for the carer, not as a data export.

**Exit criteria:**

- [ ] Renders from the same server-derived collapse and readiness as the plan page
- [ ] Indeterminate items appear in the document
- [ ] Handover note verbatim; a test asserts it reaches no CIM or pet-facts path
- [ ] Download timestamp recorded; "changed since download" notice per D-AWAY-009 with copy matching the scope chosen there

---

## AW-SEED — Seed scenario (parallel after AW-4)

New `server/db/seeds/scenarios/away-planning.js`, following `care-schedule-fixture.js`: `export async function seedAwayPlanning(client)`, idempotent via `ON CONFLICT (id) DO UPDATE`, stable UUIDs added to `demo-constants.js`.

Wiring — both edits required, and the second is the one that is easy to miss:

1. `server/db/seeds/scenarios/index.js` — import, add to the `SCENARIOS` map, **and** add to the `ALL_SCENARIOS` array. `org-v3-demo` is in the map but not the array, so map membership alone does not run it.
2. Order: **after** `care-schedule-fixture`, so absence windows can intersect its multi-per-day and `from_completion` entries rather than duplicating fixtures.

Coverage per §7: carer mix (`shared_user`, `note_only`, unset) across households; absences in each of the five coverage states including `indeterminate` via `from_completion`; multi-per-day and non-daily entries intersecting a window; past / upcoming / cancelled absences; one downloaded-then-edited plan.

**Exit criteria:**

- [ ] Scenario in `SCENARIOS` **and** `ALL_SCENARIOS`; `seed.test.js` asserts both (no such test exists today for any scenario)
- [ ] `node scripts/seed.js --scenario=away-planning` idempotent across two consecutive runs
- [ ] `docs/e2e/uat-demo-data.md` updated

---

## AW-10 — Canonical docs + journey coverage

- [care-context.md](../features/care-context.md): hub / plan page / carer model canonical; replace "Preview before save" and "pull-only" framing; record the `explainGap` window contract (D-AWAY-011)
- Carer model semantics section: `shared_user` vs `note_only`, no per-item assignment, the Pet Sitting boundary
- `care-through-change-delivery-plan.md` CC-4: mark "Pull-only; no dashboard slot" superseded — it is already contradicted by `PlannedAbsenceEntryTile` on `/pc/home`
- `docs/architecture/api-reference.md`: carer fields, `scope` parameter, enriched `uncertainties`
- New `away_planning.feature` Gherkin + Playwright spec with an exact-matching `@bdd` header (no absence or `/pc/away` scenario exists today)

---

## Explicitly out of scope

No care rescheduling or "move this occurrence" affordance, not even a stub (CSM owns it; D-CSM-008). No per-care-item carer assignment. No Pet Sitting, sitter marketplace, or sitter permission model. No public anonymous share links. No CIM changes. No automatic "holiday mode". No requirement to complete a plan before saving an absence.

---

## Related

- [away-planning-decisions.md](./away-planning-decisions.md)
- [care-context.md](../features/care-context.md)
- [care-schedule-management-delivery-plan.md](./care-schedule-management-delivery-plan.md)
- [care-through-change-delivery-plan.md](./care-through-change-delivery-plan.md)
