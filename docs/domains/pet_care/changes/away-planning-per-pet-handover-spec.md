---
title: Away Planning — Per-pet note & per-pet handover export
owner: Product / Agent
audience: both
status: draft
last_updated: 2026-09-22
tags: [pet_care, care_context, away_planning, handover, spec]
---

# Away Planning — Per-pet note & per-pet handover export

**Status:** Draft, product-reviewed — ready for engineering.
**Extends:** [away-planning-carer-model.md](../features/away-planning-carer-model.md), the existing carer model (migration `063`).
**Frozen context this must not violate:** [away-planning-decisions.md](./away-planning-decisions.md) — especially D-AWAY-004 (`note_only` never implies access), D-AWAY-008 (handover note is verbatim), D-AWAY-009 (download tracking, Part 2 deferred), D-AWAY-010 (saving never requires a complete plan).

---

## 1. Problem

Away Planning has exactly one note and one export today, both scoped to the whole absence: `planned_absences.handover_note` (one free-text field) and a single "download full plan" button that bundles every pet into one PDF (`AwayPlanHandoverController.downloadHandover`, `flutter_app/lib/features/pet_care/context/presentation/controllers/away_plan_handover_controller.dart`).

When different people care for different pets on the same trip, each carer's PDF is cluttered with — or for a `note_only` carer, actively confusing — information about pets that aren't theirs. There's also no field for pet-specific instructions: `carer_note` exists but is schema-forbidden for `shared_user` carers (`planned_absence_pets_carer_fields_check`), so a `shared_user` carer like a collaborator with existing access has nowhere to receive "feeds twice daily, evening walk only"-style notes.

**Framing that shapes the whole spec:** for a `note_only` carer, the per-pet PDF is not a trimmed convenience export — it is the *only* channel they have. They have no app access, no notification, no login (D-AWAY-004). Whatever isn't in that PDF, they don't get.

---

## 2. Model

Two additive changes. The existing absence-level note and full-plan export are unchanged.

### 2a. Per-pet note

New column on the existing per-pet join table, independent of `carer_kind` — usable for both `shared_user` and `note_only` carers, unlike `carer_note`.

```sql
ALTER TABLE planned_absence_pets ADD COLUMN pet_note TEXT NULL;
```

No interaction with the existing `planned_absence_pets_carer_fields_check` / `planned_absence_pets_carer_kind_check` constraints — orthogonal column, no migration risk to frozen carer logic.

Three distinct note fields now exist; keep them conceptually and label-wise distinct:

| Field | Scope | Meaning |
|---|---|---|
| `planned_absences.handover_note` (existing) | Whole absence | Whole-trip notes (house rules, alarm code, general logistics) |
| `planned_absence_pets.carer_note` (existing) | One pet, `note_only` carers only | About the *person* — who they are, how to reach them |
| `planned_absence_pets.pet_note` (new) | One pet, any carer kind | About *caring for this pet* — feeding, meds, quirks |

Verbatim rendering, never parsed, never fed to CIM, never promoted to structured pet facts — same boundary as D-AWAY-008, extended explicitly to this field and asserted in the same style of test.

### 2b. Per-pet export

A second export action, one PDF scoped to a single pet, reusing the existing client-side PDF pipeline (`AwayPlanHandoverService`, `pdf_saver.savePdf` — no server rendering, no new export mechanism).

---

## 3. API

### 3.1 The naive design is broken — fix required at the endpoint

Verified against `server/routes/careContext/plannedAbsencesRouter.js:121-161`. `updateAbsenceCarers` currently runs, unconditionally, for every item in `pet_carers`:

```js
await pool.query(
  `UPDATE planned_absence_pets
   SET carer_kind = $1, carer_user_id = $2, carer_name = $3, carer_note = $4
   WHERE planned_absence_id = $5 AND pet_id = $6`,
  [validated.carer_kind, validated.carer_user_id, validated.carer_name, validated.carer_note, absenceId, petId]
);
```

`validateCarerInput` (`server/lib/care/plannedAbsence.js`) collapses "`carer_kind` key absent" and "`carer_kind: null`" to the same all-null result. So `{ "pet_id": "…", "pet_note": "…" }` sent as-is would silently **wipe the carer assignment**. This is a correctness requirement, not a nice-to-have.

### 3.2 Required change

`updateAbsenceCarers` must distinguish "key present" from "key absent" per field, and build the `UPDATE` (or run two conditional updates) accordingly:

- `carer_kind` key **present** in the item (including explicit `null`, meaning clear) → validate and write carer columns, as today.
- `pet_note` key **present** → write it, independent of whether carer fields are present.
- An item with only `pet_id` + `pet_note` touches **only** `pet_note`.
- An item with only `pet_id` + `carer_kind` touches **only** carer columns (today's behavior, unchanged).
- Clearing the carer must **not** null `pet_note` — independent columns, independent intents.

```json
{ "pet_carers": [{ "pet_id": "…", "pet_note": "Feeds twice daily, evening walk only" }] }
```

### 3.3 Read side

Add `pet_note` to `carerRowToMap` / `absenceToMap` (`server/lib/care/plannedAbsence.js`) so it flows through `GET`/`PATCH` responses the same way every other per-pet fact already does.

---

## 4. UI

- **Note input:** added to the existing `AwayPlanCarerEditDialog` (`flutter_app/lib/features/pet_care/context/presentation/widgets/away_plan_carer_edit_dialog.dart`), as a field independent of the `_CarerMode` radio group — visible and saveable in every mode, including "Clear."
- **Every `_payloadForMode()` branch must include `pet_note`** when non-empty, not only the branches that also change carer fields — otherwise the independent-of-carer-kind save is unreachable from the UI even though the API supports it.
- **Export button:** second `IconButton` in `_CarerRow` (`away_plan_carers_section.dart`), `key: away_plan_download_pet_$petId`, tooltip "Download plan for {petName}", disabled when `absence.isCancelled` — same rule as the existing full-plan download.
- **Copy:** give the new field its own l10n key (EN + FR), labelled "Notes for {petName}" or equivalent — not bare "Notes," which `pdfNotesLabel` already owns for the absence-level note.

---

## 5. PDF content — per-pet document, resolved

Section-by-section, for the single-pet export:

| Section | Content |
|---|---|
| Header, date range | Same as full PDF |
| Trip pet list (Details line) | Names only, all pets on the trip — for context |
| Absence `handover_note` | **Included**, verbatim, labelled as whole-trip notes (visually distinct from the pet note section) |
| Carer coverage summary | **This pet only.** New, pet-scoped copy (e.g. "{PetName} has a carer assigned" / "No carer assigned for {PetName}") — do **not** reuse `AwayPlanCopy.carerCoverageSummary`'s existing keys (`awayPlanningCarerCoverage{All,Some,None}HaveCarers`), which are inherently cross-pet phrasing (verified in `away_plan_copy.dart:8-24`) |
| Care coverage summary | This pet's own `coverage_state`, from `getCarePeriodCoverage(petId, …)` (already fetched per pet in the existing download loop) — reuses `AwayPlanCopy.careCoverageSummary`'s existing keys as-is, since those are state-based, not aggregate-phrased |
| "Who's caring" | **This pet's row only** — no other pet's carer is named. Resolved: privacy over completeness here, even though other sections stay trip-wide. |
| Care during (schedule) | This pet's routine / dated / indeterminate lines only |
| `pet_note` | New section, verbatim, same treatment as the absence note |

**Why "Who's caring" is the one section trimmed to one pet while others stay trip-wide:** naming another pet's carer — possibly a private individual — to someone with no account and no other context for who that person is, is a real disclosure, not just noise. Dates and pet names carry no such risk; another person's name and relationship to the household does.

Implementation note: extract a shared `buildHandoverDocument({ absence, petFilter })` in the controller so the full and per-pet exports share one code path instead of the per-pet one being a hand-maintained copy of `downloadHandover` — prevents the two drifting apart the next time schedule rendering changes.

---

## 6. Behavior, pinned down

- **Filename:** `away_plan_{petSlug}_{starts}_{ends}.pdf`, slug sanitized from pet name.
- **Empty `pet_note`:** section omitted from the PDF, same pattern as `handover_note` today.
- **Download allowed with no carer assigned:** yes — consistent with D-AWAY-010 (nothing required to save).
- **`last_handover_downloaded_at` on per-pet download:** **does not bump.** This column means "the full plan was downloaded"; a per-pet export is a different, narrower action, and D-AWAY-009's Part 2 (real change detection) shouldn't inherit an ambiguous definition of what "downloaded" means. Low-stakes to revisit later since nothing currently reads the comparison, but this is the shipped default.

---

## 7. Out of scope

- Real OS print dialog (`Printing.layoutPdf`) — reuses the existing share/download mechanism (`Printing.sharePdf` on mobile, browser download on web).
- Sending the PDF directly to a `note_only` carer (email, link, in-app share) — download-and-forward by the pet parent, in their own time, is the intended v1 flow. Confirmed, not a gap: future versions of this PDF are expected to grow (e.g. vet details) rather than gain a delivery channel.
- Editing `carer_note`'s constraint to allow it on `shared_user` carers — different field, different frozen meaning (D-AWAY-003); not touched.
- Per-pet-specific download tracking or "changed since download" logic.

---

## 8. Forward-compat note

Future growth (vet details, etc.) should land as additive fields on the per-pet document data class (`AwayPlanHandoverPetSection` or its single-pet equivalent), the same way `pet_note` is being added now. No structural decision needed today beyond not hardcoding the section list in a way that resists a new field later.

---

## 9. Delivery checklist

**Server**
- [ ] Migration: `planned_absence_pets.pet_note TEXT NULL`.
- [ ] `updateAbsenceCarers`: conditional `SET`, keyed on field presence, not just value.
- [ ] `carerRowToMap` / `absenceToMap`: carry `pet_note`.
- [ ] Tests: `pet_note`-only PATCH preserves carer; carer PATCH preserves `pet_note`; clear-carer preserves `pet_note`.
- [ ] D-AWAY-008 boundary test extended to `pet_note` (verbatim, never parsed).

**Flutter**
- [ ] `PlannedAbsencePetCarer.petNote` + datasource/model parsing.
- [ ] `AwayPlanCarerEditDialog`: note field visible and saved in every mode.
- [ ] `AwayPlanCarersSection` / `_CarerRow`: per-pet download button, disabled-when-cancelled.
- [ ] `buildHandoverDocument({ absence, petFilter })` extraction; per-pet document uses pet-scoped carer/care coverage copy, not `AwayPlanReadiness` aggregates.
- [ ] New l10n keys (EN + FR): pet-note field label, pet-scoped carer coverage strings.

**Docs**
- [ ] Update [away-planning-carer-model.md](../features/away-planning-carer-model.md) and [api-reference.md](/docs/architecture/api-reference.md).
- [ ] Consider a D-AWAY-014 entry in [away-planning-decisions.md](./away-planning-decisions.md) — this spec resolves two decisions adjacent to the frozen set: handover-note inclusion in a filtered export, and carer-roster privacy in a single-pet document.

---

## 10. Delivery sizing

One atomic PR — migration, API, entity/model, dialog field, row UI, PDF builder, and tests are one cohesive outcome ("write a per-pet note and export a self-contained handover for one pet"). Suggested internal commit sequencing for review legibility:

1. Migration + API + entity (read path works).
2. Dialog field (write path).
3. PDF builder + download button.

---

*End of spec.*
