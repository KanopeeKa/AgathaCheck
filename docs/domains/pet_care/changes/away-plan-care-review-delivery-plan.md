---
title: Away Plan Care Review UX — Delivery Plan
owner: Product / Agent
audience: both
status: proposed
status_since: 2026-10-16
folds_into: docs/domains/pet_care/features/care-context.md
plan: away-plan-care-review-ux
last_updated: 2026-10-16
---

# Away Plan Care Review UX — Delivery Plan

**Canonical product behaviour:** [care-context.md](../features/care-context.md) — updated in phase **acr-5**.
**Execute-plan:** `.agents/plans/away-plan-care-review-ux.md`
**Design basis:** `/ui-design-deep` (2026-10-16) — absence create preview noise + post-save review queue.

**Status: proposed** — decisions below are **draft for DOC-0 freeze**; do not implement until `approve-autonomous away-plan-care-review-ux`.

---

## Programme goal

Pet parents should **not** see occurrence-level care lists while creating an absence. After save, the away plan should show a **care-item review queue** (title, in-trip impacted date count, **Review dates**, bulk selection)—not a flat list of every scheduled date. Navigation lands on the care item with absence review in focus.

Scheduling semantics (CSM) unchanged; this is Care Context presentation + coverage counting alignment.

---

## Design review (`/ui-design-deep`)

### 1. Problem · **requirement**

Create flow renders every row in `items[]` (occurrences), inflating “57 items to review” and showing pre-window open dates. Users interpret this as “all care dates,” including outside the trip.

### 2. Why it matters · **requirement**

Violates calm coordination (True North): operational absence flow becomes a spreadsheet before the plan exists. Erodes trust in date boundaries.

### 3. UX impact · **requirement**

- Weak hierarchy: pet card + endless checklist competes with Save.
- Wrong mental model: “items” = occurrences, not care details.
- Saved plan mixes “Planned care” schedule rows with “to review” without a dedicated queue.

### 4. A11y impact · **requirement**

Long unscannable lists on small screens; radio/checkbox affordances without bulk semantics. Fix: section headers, `Semantics(identifier: …)` on review cards and bulk bar, 48dp targets on Review dates + selectors.

### 5. System impact · **recommendation**

- Amends **CARE-CONTEXT-R-009** and **R-017** (preview/count source).
- Reuses `planned_care_items[]`, `in_window`, absence resolutions (D-CIE-013); may add a thin `review_queue` slice on coverage/readiness wire.
- PDF/handover keeps schedule parity (R-A8); screen prioritises review queue.

### 6. Proposed fix · **requirement**

| Surface | Target |
|---------|--------|
| Create `/pc/away/new` | Dates + pets only; **no** occurrence list; optional one-line per-pet coverage reassurance (no counts of dates). |
| Plan `/pc/away/:id` | Per pet: **Care to review** cards (care detail title, in-trip impacted date count, Review dates, checkbox in bulk mode). |
| Navigation | Review dates → care item detail with absence review entry (strip / occurrence sheet per care-item-evolution). |

### 7. Reusable rule · **recommendation**

**Away surfaces enumerate care items, not occurrences.** Occurrence-level `items[]` stays on the wire for projection/coverage math but is not rendered on create or plan review queues.

### 8. Implementation notes · **recommendation**

- Create: stop mapping `result.items` in `CarePeriodPetPreviewSection`; drop or replace preview block copy (`careContextAwayPreviewIntro`).
- Plan: new presentation module; consider demoting full `planned_care_items` list to “All planned care” collapsible for carers/PDF alignment.
- Count: align `has_items_to_review` copy with **unresolved affected care items**, not pending occurrence rows (server policy tweak in acr-1).
- Bulk V1: see **CARE-CONTEXT-D-008** — avoid duplicating care-item Mark/Skip bulk on the plan.

### 9. Acceptance checklist (programme)

- [ ] Theme tokens; away-context plum for absence chrome (CC-UI-D-001)
- [ ] Focus visible; touch ≥ 48dp on cards and bulk controls
- [ ] EN + FR ARB for new strings; no hard-coded counts grammar
- [ ] Loading / error / empty review queue per pet
- [ ] `AppExperience.petCare` routes only
- [ ] Widget tests + BDD + Playwright for create (no list) and plan (cards + Review dates)
- [ ] `care-context.md` requirements + decision log updated; `api-reference.md` if wire adds fields

---

## Shipping gates

1. **acr-doc-0** merges first — freeze decisions **CARE-CONTEXT-D-004 … D-008** (below).
2. **acr-1** before **acr-3** — coverage/review queue contract before Flutter plan UI.
3. **acr-2** (create) may run parallel with **acr-1** after doc-0 (Flutter-only; uses existing wire).
4. **acr-4** (navigation) after **acr-3** or in same phase if scope stays ≤500 lines/file.
5. **acr-5** last — canonical sync, BDD, E2E.
6. Integration branch must not promote to `main` until acr-5 merges (acr-2 without acr-3 is OK on branch briefly; release PR waits for full stack).

Integration branch: `cursor/away-plan-care-review-ux-integration-a227`.

---

## Frozen decisions (canonical — DOC-0)

Record in [care-context.md](../features/care-context.md) decision log and requirements table when frozen.

### CARE-CONTEXT-D-004 — No care enumeration before save · **supersedes R-009 presentation**

| | |
|---|---|
| **Decision** | On create (`/pc/away/new`), the UI **must not** list care items, care details, or scheduled dates before the absence is saved. |
| **Allowed** | Optional calm per-pet line derived from coverage state (e.g. indeterminate qualifier) **without** numeric occurrence counts or scrollable lists. |
| **Still true** | Save requires only dates + pets (R-022). Preview API may still be called for reassurance/indeterminate detection. |
| **Amends** | CARE-CONTEXT-R-009 — replace “inline care preview” with “inline care **reassurance** only, no enumeration.” |

### CARE-CONTEXT-D-005 — Review metrics use care items, not occurrences · **amends R-017**

| | |
|---|---|
| **Decision** | User-facing “to review” counts on away surfaces (header, per-pet summary, hub tile when driven by care coverage) count **affected care items** (`health_entry_id`) with **unresolved absence attention**, not pending rows in `items[]`. |
| **Wire** | `items[]` remains authoritative for projection completeness and in-window date math; coverage policy may accept a derived `review_item_count` or compute from `planned_care_items[]` + resolution state (D-CIE-013). |
| **Amends** | CARE-CONTEXT-R-017 — clarify: `items[]` for projection; **not** for away UI counts. |

### CARE-CONTEXT-D-006 — Impacted date count on review cards

| | |
|---|---|
| **Decision** | Card subtitle count = **pending in-trip dates** for that care item: `starts_on ≤ scheduled_date ≤ ends_on` and `status === pending` (same semantics as `listPlannedDatesInTrip`). |
| **Exclude** | Pre-window open occurrence dates from the card count (still surfaced on care item / pre-absence attention link per R-020). |
| **Display** | Prefer server-provided `in_window.count` when enriched; client does not re-project. |

### CARE-CONTEXT-D-007 — Review dates navigation

| | |
|---|---|
| **Decision** | **Review dates** on a plan review card opens the **care item detail** for that `health_entry_id` with absence context active. |
| **Default** | If the item needs attention and has a reviewable in-window occurrence, open the **occurrence review** entry point (same as care item absence strip **Review date** — care-item-evolution BDD). |
| **Fallback** | If only pre-window open work: land on detail with absence section visible; no silent no-op. |
| **Amends** | Extends D-AWD-005 (row tap) with explicit primary CTA and review-focused entry. |

### CARE-CONTEXT-D-008 — Bulk selection on away plan (V1 scope)

| | |
|---|---|
| **Decision** | Per-pet **Care to review** section supports **bulk mode** (toggle in section header): checkboxes on cards; sticky bulk action bar when ≥1 selected. |
| **V1 actions** | **Keep with carer** for all selected items that support it (pet has carer; per-item absence resolution API). |
| **Out of V1** | Bulk skip/reschedule/move dates on the plan (remain on care item / occurrence review). Track debt issue if product wants parity with care-item bulk Mark/Skip. |
| **Empty** | Bulk mode hidden when zero review cards. |

### CARE-CONTEXT-D-009 — Plan layout: review queue before schedule

| | |
|---|---|
| **Decision** | Saved plan per-pet section order: (1) coverage summary line, (2) **Care to review** queue when non-empty, (3) **All planned care** (existing `planned_care_items` schedule list) **collapsed by default** when review queue non-empty; expanded when queue empty. |
| **Rationale** | Carers/handover still need schedule (R-A8); pet parent primary job is review, not reading every recurrence line. |

---

## Copy proposals (ARB — freeze in acr-doc-0)

| Key | EN (draft) | Notes |
|-----|------------|-------|
| `careContextAwayCreateReassuranceIntro` | “After you save, you can review care that falls during these dates.” | Replaces list intro on create |
| `careContextAwayReviewSectionTitle` | “Care to review” | Per-pet section |
| `careContextAwayReviewImpactedDates` | `{count, plural, =1{1 date during your absence} other{{count} dates during your absence}}` | Card subtitle |
| `careContextAwayReviewDatesAction` | “Review dates” | Primary button |
| `careContextAwayReviewBulkKeepCarer` | “Keep with carer” | Bulk bar |
| `careContextAwayPlannedCareExpand` | “All planned care” | Collapsed schedule |
| `careContextCoverageHasCareItemsToReview` | `{count, plural, =1{1 care item to review} other{{count} care items to review}}` | Replaces occurrence-based count copy where D-005 applies |

Tone: assume commitment, no blame ([copy-tone.md](/docs/design/copy-tone.md)).

---

## Phase table

| Phase | Outcome | Depends on |
|-------|---------|------------|
| **acr-doc-0** | Freeze D-004…D-009; this doc `status: in-delivery`; execute-plan snapshot validated | — |
| **acr-1** | Server: review-item coverage counts + optional `review_queue` enrichment on care-period coverage / readiness | acr-doc-0 |
| **acr-2** | Flutter create: remove occurrence preview list; reassurance-only copy | acr-doc-0 |
| **acr-3** | Flutter plan: review cards, bulk mode V1, collapsed schedule | acr-1 |
| **acr-4** | Navigation: Review dates → care item absence review entry | acr-3 |
| **acr-5** | Canonical `care-context.md`, api-reference, BDD + Playwright | acr-1…acr-4 |

```text
acr-doc-0
   ├── acr-1 ──> acr-3 ──> acr-4 ──┐
   └── acr-2 ──────────────────────┼──> acr-5
```

---

## Phase detail (execute-plan)

### acr-doc-0 — Bootstrap

- Freeze decisions in this file; set `status: in-delivery`.
- Open control issue; `node scripts/execute_plan_runtime.js init away-plan-care-review-ux` after snapshot on init branch.
- User: `approve-autonomous away-plan-care-review-ux` on control issue.

### acr-1 — Server review metrics

- Extend away-plan coverage evaluation to expose care-item review count consistent with D-005/D-006.
- Optional wire: `review_queue: [{ health_entry_id, name, type, care_family, impacted_date_count, bulk_keep_carer_eligible }]`.
- Tests: `server/test/careContext/**`, `server/test/care/absence/**` — pre-window excluded from impacted count; resolved items excluded from queue.
- `docs/architecture/api-reference.md` if wire changes.

### acr-2 — Create flow (no enumeration)

- `planned_absence_flow_screen.dart` / `planned_absence_preview_step.dart` / `care_period_pet_preview_section.dart`.
- Remove `_PreviewItemRow` list; optional loading/error + one-line reassurance.
- Widget tests + update `planned_absence_edit` if shared preview.

### acr-3 — Plan review queue UI

- New widgets under `flutter_app/lib/features/pet_care/context/presentation/widgets/` (e.g. `away_plan_care_review_section.dart`).
- Integrate in `away_plan_pet_care_section.dart` per D-009.
- Semantics identifiers for E2E: `away_plan_review_card_{entryId}`, `away_plan_review_bulk_toggle`, etc.
- Widget tests: card fields, bulk bar visibility, collapsed schedule.

### acr-4 — Review dates navigation

- `openPetEventView` extension or query param documented in care-item-evolution cross-link.
- Flutter: pass absence id + `openReview: true` where router supports it; else document debt and land on detail with scroll-to absence section.
- BDD step glue in Playwright page object.

### acr-5 — Docs and journeys

- `/canonical-docs sync` → `care-context.md` (requirements R-009, R-017 text; new R-023…R-025 if needed).
- Fold this delivery plan; delete when fully delivered.
- `flutter_app/test/bdd/features/away_plan_care_review.feature` + Playwright `@bdd` spec.
- Amend `away_planning.feature` create scenario: assert no occurrence rows before save.

---

## Out of scope

- Editing absence dates/pets on create (unchanged).
- New absence resolution types or carer model changes.
- Bulk skip/mark on away plan (debt).
- Changing `projectSchedule` occurrence materialisation (pre-window open still exists; not shown on create list).

---

## Risks

| Risk | Mitigation |
|------|------------|
| Coverage count behaviour change breaks hub tile / PDF | Limit D-005 to away create/plan copy; PDF uses schedule rows; regression tests on readiness facts |
| Review navigation not deep-linkable on web | Semantics + query param; fallback scroll-target on absence section |
| File size CI | Split widgets/controllers under 500 lines |
