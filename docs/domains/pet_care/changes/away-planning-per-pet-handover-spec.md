---
title: Away Planning — Per-pet note & per-pet handover export
owner: Product / Agent
audience: both
status: active
last_updated: 2026-09-22
tags: [pet_care, care_context, away_planning, handover, spec]
---

# Away Planning — Per-pet note & per-pet handover export

**Status:** Active — ready for engineering; D-AWAY-014 freezes on implementation PR merge.
**Extends:** [away-planning-carer-model.md](../features/away-planning-carer-model.md), the existing carer model (migration `063`).
**Delivery context:** Post-AW-9 follow-on; add a row to [away-planning-delivery-plan.md](./away-planning-delivery-plan.md) when implementation starts.
**Frozen context this must not violate:** [away-planning-decisions.md](./away-planning-decisions.md) — especially D-AWAY-004 (`note_only` never implies access), D-AWAY-008 (handover note is verbatim), D-AWAY-009 (download tracking, Part 2 deferred), D-AWAY-010 (saving never requires a complete plan).
**New proposed decisions (freeze on merge):** D-AWAY-014 — see [§11](#11-proposed-decisions-d-away-014).

---

## 1. Problem

Away Planning has exactly one note and one export today, both scoped to the whole absence: `planned_absences.handover_note` (one free-text field) and a single "download full plan" button that bundles every pet into one PDF (`AwayPlanHandoverController.downloadHandover`, `flutter_app/lib/features/pet_care/context/presentation/controllers/away_plan_handover_controller.dart`).

When different people care for different pets on the same trip, each carer's PDF is cluttered with — or for a `note_only` carer, actively confusing — information about pets that aren't theirs. There's also no field for pet-specific instructions: `carer_note` exists but is schema-forbidden for `shared_user` carers (`planned_absence_pets_carer_fields_check`), so a `shared_user` carer like a collaborator with existing access has nowhere to receive "feeds twice daily, evening walk only"-style notes.

**Framing that shapes the whole spec:** for a `note_only` carer, the per-pet PDF is not a trimmed convenience export — it is the *only* channel they have. They have no app access, no notification, no login (D-AWAY-004). Whatever isn't in that PDF, they don't get.

---

## 2. Model

Two additive changes. The absence-level note and full-plan export **behaviour** are unchanged except where this spec explicitly adds `pet_note` rendering to the full PDF (see §2b).

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

**Plan page (v1):** `pet_note` is editable only in `AwayPlanCarerEditDialog`, not shown inline on the plan page row. Intentional — avoids scope creep; revisit in a follow-up if parents need at-a-glance visibility.

### 2b. Export

**Per-pet export (new):** a second export action, one PDF scoped to a single pet, reusing the existing client-side PDF pipeline (`AwayPlanHandoverService`, `pdf_saver.savePdf` — no server rendering, no new export mechanism).

**Full-plan export (additive only):** when generating the existing full PDF, include each pet's non-empty `pet_note` under that pet's block in "Care during" (or an adjacent per-pet notes subsection). All other full-PDF behaviour stays as today — absence-wide coverage summaries, all pets' schedules, and `recordHandoverDownload` on completion.

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

- **Key presence** uses own-property checks (`Object.hasOwn(item, 'carer_kind')` / `Object.hasOwn(item, 'pet_note')`), accepting both snake_case and camelCase wire names (`carer_kind` / `carerKind`, `pet_note` / `petNote`) — same pattern as `validateCarerInput`.
- `carer_kind` key **present** in the item (including explicit `null`, meaning clear) → validate and write carer columns, as today.
- `pet_note` key **present** → write it (after normalization — see below), independent of whether carer fields are present.
- An item with only `pet_id` + `pet_note` touches **only** `pet_note`.
- An item with only `pet_id` + `carer_kind` touches **only** carer columns (today's behavior, unchanged).
- Clearing the carer must **not** null `pet_note` — independent columns, independent intents.

**Normalization:** add `normalizePetNoteInput` (mirror `normalizeHandoverNoteInput` in `plannedAbsenceHandoverFields.js`): `undefined` → omit from UPDATE; `null` or `""` → store `NULL`; otherwise store the string as-is (verbatim, no trimming beyond empty-to-null).

```json
{ "pet_carers": [{ "pet_id": "…", "pet_note": "Feeds twice daily, evening walk only" }] }
```

```json
{ "pet_carers": [{ "pet_id": "…", "pet_note": null }] }
```

The second form clears `pet_note` without touching carer columns.

### 3.3 Read side

Add `pet_note` to `carerRowToMap` / `absenceToMap` (`server/lib/care/plannedAbsence.js`) so it flows through `GET`/`PATCH` responses the same way every other per-pet fact already does.

---

## 4. UI

- **Note input:** added to the existing `AwayPlanCarerEditDialog` (`flutter_app/lib/features/pet_care/context/presentation/widgets/away_plan_carer_edit_dialog.dart`), as a field independent of the `_CarerMode` radio group — visible and saveable in every mode, including "Clear." Initialize from `currentCarer.petNote` regardless of carer mode.
- **Every `_payloadForMode()` branch must always include `pet_note`** (normalized: empty string → `null`), not only when non-empty — otherwise clearing the field from the UI is unreachable even though the API supports it.
- **Export button:** second `IconButton` in `_CarerRow` (`away_plan_carers_section.dart`), `key: away_plan_download_pet_$petId`, icon `Icons.picture_as_pdf_outlined` (same family as the full-plan app-bar button), tooltip "Download plan for {petName}", disabled when `absence.isCancelled` — same rule as the existing full-plan download.
- **Copy:** give the new field its own l10n key (EN + FR), labelled "Notes for {petName}" or equivalent — not bare "Notes," which `pdfNotesLabel` already owns for the absence-level note.

---

## 5. PDF content

### 5.1 Per-pet document

Section-by-section, for the single-pet export:

| Section | Content |
|---|---|
| Header, date range | Same as full PDF |
| Trip pet list (Details line) | Names only, all pets on the trip — for context |
| Absence `handover_note` | **Included**, verbatim, under a **trip-wide** section title (new l10n key, e.g. "Trip notes" / "Notes for the whole trip" — not `pdfNotesLabel` alone) |
| Carer coverage summary | **This pet only.** New, pet-scoped copy — do **not** reuse `AwayPlanCopy.carerCoverageSummary`'s existing keys (`awayPlanningCarerCoverage{All,Some,None}HaveCarers`), which are inherently cross-pet phrasing (verified in `away_plan_copy.dart:8-24`). States: |
| | • Has carer → "{PetName} has a carer assigned" |
| | • Unset → "No carer assigned for {PetName}" |
| | • `carer_removed` → "Carer removed for {PetName}" (mirror `awayPlanningCarerRemoved` tone) |
| Care coverage summary | This pet's own `coverage_state`, from `getCarePeriodCoverage(petId, …)` (already fetched per pet in the existing download loop) — reuses `AwayPlanCopy.careCoverageSummary`'s existing state-based keys. When `coverage_state` is `has_items_to_review`, set `copyCount` from **this pet's** pending projection items (`coverage.items.where((item) => item.isPending).length` in Dart), not from `AwayPlanReadiness` aggregates. |
| "Who's caring" | **This pet's row only** — no other pet's carer is named. Resolved: privacy over completeness here, even though other sections stay trip-wide. |
| Care during (schedule) | This pet's routine / dated / indeterminate lines only |
| `pet_note` | New section under a **pet-specific** title (new l10n key, aligned with dialog label — e.g. "Notes for {PetName}"), verbatim, same treatment as the absence note |

**Why "Who's caring" is the one section trimmed to one pet while others stay trip-wide:** naming another pet's carer — possibly a private individual — to someone with no account and no other context for who that person is, is a real disclosure, not just noise. Dates and pet names carry no such risk; another person's name and relationship to the household does.

**Pet parent responsibility:** trip-wide `handover_note` may contain logistics (alarm code, etc.) meant for every carer on the trip. Pet parents should not put other-pets' secrets in the absence note if they export per-pet PDFs to different people.

### 5.2 Full-plan document (additive)

Under each pet's block in "Care during", render that pet's non-empty `pet_note` in the same verbatim style. No other structural changes to the full PDF.

**Access note (pre-existing, not introduced by this spec):** full-plan download visibility follows existing absence access (`userCanManagePet` on declaration/edit). A collaborator on one pet may already see other pets' names, schedules, and carers in the full PDF; adding `pet_note` extends that surface. Per-pet export is the privacy-trimmed alternative. Tightening full-PDF access by pet is out of scope.

### 5.3 Implementation note

Extract a shared `buildHandoverDocument({ absence, petFilter, readiness?, perPetCoverage? })` in the controller:

- **Full export** passes `readiness` (absence-wide aggregates) and no `petFilter`.
- **Per-pet export** passes `petFilter` (single `petId`), per-pet coverage facts, and **does not** use `AwayPlanReadiness` aggregates.

Both paths share schedule-line rendering so they cannot drift. Full export continues to call `recordHandoverDownload` on success; per-pet export does not (D-AWAY-014b).

Store `pet_note` on `AwayPlanHandoverPetSection.petNote` (per-pet data class), not on the document root.

---

## 6. Behavior, pinned down

- **Filename:** `away_plan_{petSlug}_{starts}_{ends}.pdf`, slug sanitized from pet name.
- **Empty `pet_note`:** section omitted from the PDF, same pattern as `handover_note` today.
- **Download allowed with no carer assigned:** yes — consistent with D-AWAY-010 (nothing required to save).
- **`last_handover_downloaded_at` on per-pet download:** **does not bump** (D-AWAY-014b). Only the full-plan download updates this column (D-AWAY-009 Part 1, unchanged). Households that only ever use per-pet exports will never set the timestamp — acceptable until Part 2 change detection ships; document as a known limitation.

---

## 7. Out of scope

- Real OS print dialog (`Printing.layoutPdf`) — reuses the existing share/download mechanism (`Printing.sharePdf` on mobile, browser download on web).
- Sending the PDF directly to a `note_only` carer (email, link, in-app share) — download-and-forward by the pet parent, in their own time, is the intended v1 flow. Confirmed, not a gap: future versions of this PDF are expected to grow (e.g. vet details) rather than gain a delivery channel.
- Editing `carer_note`'s constraint to allow it on `shared_user` carers — different field, different frozen meaning (D-AWAY-003); not touched.
- Per-pet-specific download tracking or "changed since download" logic.
- Inline display of `pet_note` on the plan page (outside the carer dialog).

---

## 8. Forward-compat note

Future growth (vet details, etc.) should land as additive fields on the per-pet document data class (`AwayPlanHandoverPetSection`), the same way `pet_note` is being added now. No structural decision needed today beyond not hardcoding the section list in a way that resists a new field later.

---

## 9. Delivery checklist

**Server**
- [ ] Migration: `planned_absence_pets.pet_note TEXT NULL` (next number in `db/migrations/` after manifest head — `071` on current `main`).
- [ ] Migration test file (`server/test/migrations/0NN_planned_absence_pet_note.test.js`) — same pattern as `063` / `064`.
- [ ] `updateAbsenceCarers`: conditional `SET`, keyed on field presence (`Object.hasOwn`), not just value.
- [ ] `normalizePetNoteInput` (mirror handover-note helper).
- [ ] `carerRowToMap` / `absenceToMap`: carry `pet_note`.
- [ ] Tests (`plannedAbsenceCarers.test.js`): `pet_note`-only PATCH preserves carer; carer PATCH preserves `pet_note`; clear-carer preserves `pet_note`; `pet_note: null` clears field.
- [ ] D-AWAY-008 boundary test extended to `pet_note` (verbatim, never parsed).

**Flutter**
- [ ] `PlannedAbsencePetCarer.petNote` + datasource/model parsing.
- [ ] `AwayPlanCarerEditDialog`: note field visible, initialized, and saved in every mode; always sends normalized `pet_note`.
- [ ] `AwayPlanCarersSection` / `_CarerRow`: per-pet download button, disabled-when-cancelled.
- [ ] `buildHandoverDocument` extraction; per-pet document uses pet-scoped carer/care coverage copy, not `AwayPlanReadiness` aggregates.
- [ ] `AwayPlanHandoverPetSection.petNote` + full-PDF per-pet note rendering.
- [ ] Full export still calls `recordHandoverDownload` on success.
- [ ] Update `away_plan_carer_edit_test.dart` and `away_plan_handover_service_test.dart`.
- [ ] New l10n keys (EN + FR): dialog pet-note label; pet-scoped carer coverage strings (has / unset / removed); PDF trip-notes section title; PDF pet-notes section title.

**Docs**
- [ ] Update [away-planning-carer-model.md](../features/away-planning-carer-model.md) and [api-reference.md](/docs/architecture/api-reference.md).
- [ ] On PR merge: copy §11 into [away-planning-decisions.md](./away-planning-decisions.md) with **Status: Frozen** and bump `last_updated`.
- [ ] Add implementation row to [away-planning-delivery-plan.md](./away-planning-delivery-plan.md).

---

## 10. Delivery sizing

One atomic PR — migration, API, entity/model, dialog field, row UI, PDF builder, and tests are one cohesive outcome ("write a per-pet note and export a self-contained handover for one pet"). Suggested internal commit sequencing for review legibility:

1. Migration + API + entity (read path works).
2. Dialog field (write path).
3. PDF builder + download button.

---

## 11. Proposed decisions (D-AWAY-014)

**Status:** Proposed — freezes when the implementation PR merges.

Until merge, treat §11 as **normative for implementation** but **not** as entries in the frozen decision log. If implementation discovers a conflict with D-AWAY-001–013, escalate before changing 014a/b silently.

Copy these entries into `away-planning-decisions.md` with **Status: Frozen** as part of landing the implementation PR:

### D-AWAY-014a — Per-pet handover PDF content & privacy (2026-09-22)

Per-pet handover PDF includes trip context (dates, all pet **names**), absence `handover_note` (trip-wide section), this pet's carer row only in "Who's caring", this pet's schedule and `pet_note`, and per-pet (not absence-wide) coverage summaries. Other pets' carer identities are not disclosed.

### D-AWAY-014b — Download timestamp is full-plan only (2026-09-22)

`last_handover_downloaded_at` is updated only by the full-plan handover download (`AwayPlanHandoverController.downloadHandover`). Per-pet export does not bump it. D-AWAY-009 Part 2 change detection, when it ships, applies to full-plan download semantics only.

---

*End of spec.*
