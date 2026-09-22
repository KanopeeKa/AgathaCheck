---
title: Away Plan Detail V2 — Decision log
owner: Product / Agent
audience: both
status: active
last_updated: 2026-09-22
tags: [pet_care, care_context, away_planning, decisions]
---

# Away Plan Detail V2 — Decision log

Frozen product and engineering decisions for **Away Plan Detail V2** — a redesign of the Away Plan detail screen (`PlannedAbsencePlanScreen`, `/pc/away/:id`) shipped in **Away Planning V1** ([away-planning-decisions.md](./away-planning-decisions.md), confirmed 2026-09-15, all phases merged).

**Confirmed 2026-09-22** after two chat review rounds (no further blocking findings on round 2). All decisions below are **Frozen**. Decisions that supersede a V1 decision are called out explicitly; V1 decisions not mentioned here are unchanged.

**Reviewed 2026-09-22 (round 1):** external review confirmed the plan is grounded and phase-ready, and flagged contract-edge gaps — wire shape for the unified list, `anchor_kind` derivation, chain-explainer copy, an icon-helper mismatch, one allowed-path overlap, and snapshot placeholder hygiene. All addressed below; changed subsections are marked **(revised)**. [away-planning-decisions.md](./away-planning-decisions.md) has matching amendment blocks under D-AWAY-002 and D-AWAY-006.

**Reviewed 2026-09-22 (round 2):** confirmed round 1 fixes land correctly; no further blocking findings. Three optional clarifications folded in, marked **(added per review round 2)**: raw `items[]` stays on the wire (D-AWD-002), an integration-branch shipping gate for the AWD-2→AWD-3 window (delivery plan), and the "Repeats" vs "Occurs" copy call confirmed by the user.

**Context:** AgathaTrack is not in production; no real user data exists. Verified against `main` (post Away Planning V1, all AW-phases merged, plus Care Schedule Management V1 and Care Family icon work).

**Rebased 2026-09-22 onto AW-11 (per-pet handover, merged same day, `main@6d2b238`):** a parallel session shipped per-pet handover notes + per-pet PDF export while this plan was under review. Additive, not contradictory, but it touched four files this plan also touches — noted at each affected decision below and carried into the delivery plan's file-level detail. Implementers: **read the current file content before editing** — this doc describes the target structure, not necessarily today's exact bytes.

---

## D-AWD-001 — Plan-page readiness becomes attention-only (supersedes part of D-AWAY-002)

**Status:** Frozen (confirmed 2026-09-22 after 2 review rounds; user authorized implementation)

**Origin:** user request — "Remove the text warning/description for Carer Coverage and Care coverage. It is not necessary as it's clear in the fields below." Reviewed and narrowed: full removal would drop the "reassure and stop" behaviour that `design.mdc` calls out as a voice principle, and that D-AWAY-002 built for exactly this reason. Compromise: keep the fact, drop the line when it isn't actionable.

**Rule (plan page only — `AwayPlanHeaderSection`):**

- **Carer coverage** line renders only when `readiness.carerCoverage.state != all_have_carers` (i.e. some or none have a carer). When all pets have a carer, render nothing — the per-pet carer cards below already say so.
- **Care coverage** line renders only when `readiness.careCoverage.coverageState` is `has_items_to_review` or `indeterminate`. The reassuring states (`nothing_scheduled`, `all_completed`, `no_unresolved_items`) render nothing — the per-pet "Planned care" cards below already carry that detail (D-AWD-002/003 below).
- Both lines keep their existing copy (`AwayPlanCopy.carerCoverageSummary` / `careCoverageSummary`) when shown — no new wording, no icon/severity styling added in this pass (out of scope; a colour/severity treatment is a natural follow-up, not bundled here).
- **Not changed:** the dashboard tile's fixed-priority readiness rule (D-AWAY-002 §Dashboard tile) and the handover PDF's carer/care coverage section — the PDF is read by someone with no "fields below" to check against, so it keeps both lines unconditionally. Revisit PDF wording only if review asks for it.

**Rejected:** removing the lines entirely (loses the "am I covered?" answer above the fold); keeping them unconditionally (redundant with the sections below in the common case, which was the original complaint).

---

## D-AWD-002 — Care events are grouped by health entry, not by time slot, across all frequencies (supersedes D-AWAY-006's grouping key)

**Status:** Frozen (confirmed 2026-09-22 after 2 review rounds; user authorized implementation)

**Origin:** user request to replace the "Dated care" vs "Indeterminate care" split with one "Planned care" list: icon + title, then `Occurs every X (or single care) from A until B`, `Next due date` (only for once-per-day events), and a `Time of day` line per distinct time.

**Current state (pre-AWD-2: `server/lib/care/awayPlan/presentation.js#splitRoutineAndDatedItems`, not `recurrenceHelper.js` — corrected post-implementation, this symbol never lived in `recurrenceHelper.js`):** only `frequency === 'daily'` entries collapse, keyed by `health_entry_id + scheduled_time` — a twice-daily medication produces **two** routine rows today, not one row with two times. Every other frequency (`weekly`, `monthly`, `yearly`, `custom`) is left as individual per-occurrence "dated" rows, with no recurrence metadata surfaced. `uncertainties[]` is a third, separately-shaped array.

**(revised) Wire contract: one array, not three.** Review round 1 flagged that AWD-2 originally still shaped `routine_items` / `dated_items` / `uncertainties` separately and left merge order, dedupe, and the mixed-type row model to be improvised client-side in AWD-3. Fixed by moving the merge server-side, consistent with D-AWAY-001's "facts computed server-side at read time" principle:

- The coverage/projection response exposes a single array per pet, **`planned_care_items[]`**, replacing `routine_items`, `dated_items`, and `uncertainties` outright. Not a deprecation/compat shim — AgathaTrack has no production traffic (per this doc's Context line), so the old fields are removed, not versioned alongside the new one.
- Each item carries an explicit discriminant, **`kind`**, one of:
  - `recurring_calendar` — repeating frequency, `recurrence_anchor = 'from_due_date'`
  - `recurring_chain` — repeating frequency, `recurrence_anchor = 'from_completion'`
  - `single_once` — `frequency = 'once'`, concrete scheduled date
  - `indeterminate_pending` — no materialised occurrence yet in the window and no calendar date to show (today's `uncertainties[]` case)
- `kind` is computed server-side from **`recurrence_anchor`** (D-CSM-001; `RECURRENCE_ANCHOR_FROM_COMPLETION` / `RECURRENCE_ANCHOR_FROM_DUE_DATE`, `server/lib/care/schedule/recurrenceAnchorDefaults.js`) plus whether the entry has a materialised occurrence in the window — **not** a separate `anchor_kind` field. (Round 1 proposed `anchor_kind` as its own field derived from `recurrence_anchor` **or** occurrence certainty; collapsing it into `kind` removes a second field that would otherwise have to stay consistent with the first, and uses the authoritative per-entry attribute instead of an occurrence-level flag that can legitimately vary across a group's constituents.)
- **Dedupe rule:** exactly one row per `health_entry_id` in a pet's `planned_care_items[]`. When a `from_completion`-anchored entry has *both* materialised (dated) occurrences and a pending not-yet-materialised one in the same window, it is **one row** with `kind: recurring_chain` — never split into a separate indeterminate row for the same entry. The least-certain-wins rule (D-AWAY-006, unchanged) already governs this at the constituent level; this just guarantees it surfaces as one row, not two.
- **Sort order (server-side, so screen and PDF can't diverge):** `kind` bucket order `recurring_calendar` → `recurring_chain` → `single_once` → `indeterminate_pending`, then `name.localeCompare()` within each bucket. Same ordering the existing `routineItems` sort already uses (name, then time) — extended, not reinvented.
- Group row (kind = `recurring_calendar` / `recurring_chain`) carries: `health_entry_id`, `name`, `type`, `care_family`, `frequency`, `frequency_interval`, distinct `times_of_day: string[]` (sorted, deduped across constituents; empty array = all-day/untimed), `occurrence_count`, `status_counts`, `first_scheduled_date`, `last_scheduled_date`, `certainty` (**unchanged from D-AWAY-006:** minimum among constituents; `conditional_on_future_completion` anywhere in the group ⇒ renders as `~`).
- **`frequency === 'once'` entries are never grouped** (`kind: single_once` or `indeterminate_pending`). Each stays its own row, one per occurrence — user's explicit call: *"for dated occurrence -> show them all in a list."* These map 1:1 to today's individual dated rows; only their on-screen template changes (D-AWD-004).
- `next_due_date` (earliest **pending** occurrence date in the projected window) is computed **only for `kind: recurring_calendar` when `times_of_day.length <= 1`** — i.e. the event fires at most once per calendar day, on a fixed schedule. `null` for every other `kind`, and `null` whenever `times_of_day.length > 1`, per the user's explicit rule: *"if it's an event that happens multiple times a day every day, don't show that line."*

**Not in scope:** changing Care Schedule Management's projection engine (`server/lib/care/schedule/projectSchedule.js`) or occurrence materialisation. This is a read-side regrouping in `recurrenceHelper.js` / `server/lib/care/awayPlan/presentation.js` only — the underlying occurrence data (source of truth) is untouched. Projection corpus for CSM itself must stay byte-identical, same guarantee V1's AW-3 made.

**(added per review round 2) Raw `items[]` is untouched and stays on the wire.** `CarePeriodCoverageResult.items` (the flat per-occurrence list) feeds `CarePeriodCoverageCopy._pendingCount` (coverage summary count, D-AWD-001) and the create-flow preview (`CarePeriodPetPreviewSection`) — neither of those consumes `routine_items`/`dated_items`/`uncertainties` today, and neither should be repointed at `planned_care_items[]`. AWD-2 replaces only the three fields named above; `items[]` is out of scope and must still be present, unchanged, in the response.

---

## D-AWD-003 — Completion-chain (indeterminate) items get an interval description, not just a reason code (extends D-AWAY-007)

**Status:** Frozen (confirmed 2026-09-22 after 2 review rounds; user authorized implementation)

**Origin:** user request — indeterminate/chain-dependent items ("waiting on a prior dose") still have a recurrence rule, e.g. "every 10 days from the last occurrence"; that's what should render, plus one explanatory line at the bottom of the plan.

**Rule:**

- `kind: recurring_chain` (D-AWD-002) rows show an "occurs every" line anchored to the **last known occurrence** instead of a calendar date range — never a fabricated calendar date, never `next_due_date` (omitted unconditionally, regardless of `times_of_day`).
- `kind: indeterminate_pending` rows (genuinely no interval — a `once` entry pending on a prior chain step) fall back to today's reason copy (`awayPlanningIndeterminatePending` / `…Chain` / `…Generic`) — unchanged.
- The plan page adds **one static explanatory line**, rendered once per pet-care section (not per row) when at least one visible event in that pet's list has `kind: recurring_chain` or `indeterminate_pending` — not per row, to avoid repeating the same caveat next to every affected event. Placement: bottom of the "Planned care" card, below the event list.

**(revised) Copy drafted, not TBD.** Review round 1 flagged that leaving exact wording to implementation invites tone drift and a second review pass mid-sprint. Drafted below, checked against `docs/design/copy-tone.md` (plain, operational, no blame) and reusing existing app vocabulary rather than inventing new terms — **`[proposed]`, confirm in AWD-DOC-0, not final until then:**

| Key | EN | Notes |
|---|---|---|
| `awayPlanningEventRepeatsFromUntil` | "Repeats every {interval} {period} from {start} until {end}" | `kind: recurring_calendar`. Reuses "Repeats every {interval} {period}" from the existing `recurrenceRepeatsEveryUntil` key (`app_en.arb:1816`) rather than the user's original literal "Occurs every" — same params (`interval: int`, `period: String`), adds a `{start}` clause `recurrenceRepeatsEveryUntil` doesn't have. **Confirmed by user 2026-09-22:** "Repeats" over "Occurs", for in-app copy consistency. |
| `awayPlanningEventRepeatsFromCompletion` | "Repeats every {interval} {period}, from completion" | `kind: recurring_chain`. Reuses the exact phrase "From completion" from `recurrenceFromCompletion` (`app_en.arb:462`) — the same term the health-entry form already uses for this anchor, so a pet parent who set the schedule up recognises it here. |
| `awayPlanningEventSingleCareOn` | "Single care on {date}" | `kind: single_once`. No existing equivalent found. |
| `awayPlanningEventNextDueDate` | "Next due date: {date}" | Wording matches existing `recurrenceAnchorTitle` / `nextOccurrence` (`app_en.arb:461,1826` — two keys, same EN string today). **Implementation note:** use whichever of the two `CareItemDetailScreen` itself already displays, so the term is identical across the D-AWD-005 tap-through, not just similar. |
| `awayPlanningEventTimeOfDay` | "Time of day: {time}" | One line per distinct `times_of_day` entry. |
| `awayPlanningChainAnchorExplainer` | "Dates for some care events depend on when the previous one is completed, and may shift." | Once per pet section, per the rule above. |

FR strings drafted in AWD-DOC-0 alongside EN, same review pass — not listed here to keep this table scannable.

---

## D-AWD-004 — One unified "Planned care" list replaces Routine / Dated / Indeterminate sections

**Status:** Frozen (confirmed 2026-09-22 after 2 review rounds; user authorized implementation)

**Rename:** "Dated care" → **"Planned care"** (`awayPlanningScheduleDatedTitle` copy key repurposed as the single section heading; `awayPlanningScheduleRoutineTitle` and `awayPlanningScheduleIndeterminateTitle` retire as section headings — the distinction moves into per-row copy, not separate headings).

**Row template** — one formatter, keyed off the server-computed `kind` discriminant (D-AWD-002), rendered in the server-computed sort order (also D-AWD-002) — no client-side type inference, no client-side merge/sort:

```
[CareFamilyIcon]  {event title}
                   {schedule line — selected by item.kind:}
                     recurring_calendar    → "Repeats every {interval} {period} from {start} until {end}"
                     recurring_chain       → "Repeats every {interval} {period}, from completion"
                     single_once           → "Single care on {date}"
                     indeterminate_pending → "{indeterminate reason}"
                   "Next due date: {date}"                     (only when kind = recurring_calendar AND times_of_day.length <= 1)
                   "Time of day: {time}"  × N                  (one line per distinct time_of_day, only when present)
```

Exact ARB keys/copy in D-AWD-003.

**(revised) Icon factory.** `CareFamilyIcon.materialIconFor(...)` returns raw `IconData` and would be a **third** icon path alongside the app's two existing ones (`CareFamilyIcon.forEntry(...)` used by `health_entry_card.dart`/`care_event_row.dart`, which resolves custom glyphs for families like dental/wellness, not just the Material fallback). Review round 1 caught this. Fixed: AWD-3 adds a new named constructor, **`CareFamilyIcon.forWire({required String? type, required String? careFamily, double size, bool showChip})`**, mirroring `.forEntry`'s inference and custom-glyph handling but sourced from the wire's `type`/`care_family` strings instead of a full `HealthEntry` object (no synthetic/fake `HealthEntry` construction). One widget, two entry points into the same rendering logic — not a new icon system.

**Not shown per row any more:** the old per-occurrence completed/skipped/pending status glyph on dated rows. Trade-off flagged and accepted by the user: the plan page becomes a forward-looking schedule view; occurrence-level completion tracking is one tap away (D-AWD-005) rather than duplicated inline. **(revised, strengthened per review round 1):** for a carer scanning "what's left this week," the row must still answer that without opening detail — the `Next due date` / `Single care on {date}` line is the discoverability mechanism, not a decoration. AWD-3 exit criteria (delivery plan) require a widget test asserting a pending once-off or once-per-day item is identifiable from the row alone, not only via tap-through.

---

## D-AWD-005 — Care events are tappable; navigation reuses the existing Care Item Detail screen

**Status:** Frozen (confirmed 2026-09-22 after 2 review rounds; user authorized implementation)

**Origin:** user request — "clicking on one event should take you to the event itself — where carer will be able to see history and upcoming occurrences."

**Rule:** each unified care-event row is a single tap target (whole row, ≥48×48, per `design.mdc` touch rule) navigating to the existing route `petEventView` → `/pet/:petId/events/:entryId` (`CareItemDetailScreen`). `petId` is already in scope in `AwayPlanPetCareSection`; `entryId` is `item.healthEntryId`, present on every `planned_care_items[]` row regardless of `kind` (D-AWD-002) — was already present on all three pre-merge item types (`CarePeriodRoutineItem`, `CarePeriodProjectionItem`, `CarePeriodUncertainty`), so the field survives the merge unchanged. **No new screen, no new route.**

**Authorization:** unchanged. Anyone viewing the away plan already holds the `pet_access` that `CareItemDetailScreen` itself requires. `note_only` carers have no app access at all (D-AWAY-004) and never reach either screen — this tap-through creates no new exposure.

---

## D-AWD-006 — Pet header gets a photo + tap-through to the pet profile

**Status:** Frozen (confirmed 2026-09-22 after 2 review rounds; user authorized implementation)

**Origin:** user request — "would be nice to add the pet profile picture next to its name + link to the pet screen."

**Rule:** `AwayPlanPetCareSection`'s per-pet header gets a 32px circular pet photo left of the pet name, reusing the existing `CareEventRowPetAvatar` pattern (`buildPetPhotoOrPlaceholder`, `flutter_app/lib/features/health_tracking/presentation/widgets/care_event_row_pet_avatar.dart`) — not a new avatar component. The header row becomes a single tap target navigating to the existing `petDetail` route → `/pet/:petId` (`PetDetailScreen`).

Applied to `AwayPlanCarersSection`'s per-pet row too, in the same phase, since it's the identical widget with no new logic — bundling avoids a near-duplicate follow-up PR for one extra call site.

**(added, AW-11 rebase) That row now has two `IconButton`s** (edit carer, download per-pet PDF — AW-11), not one. Wrap only the avatar+name portion in the tap target for `petDetail`, not the whole row — a row-length `InkWell` behind two nested icon buttons is an accessibility footgun (ambiguous tap target, confusing focus order) `accessibility.mdc` would flag.

---

## D-AWD-007 — Plan page becomes read-only; a new edit screen owns writes

**Status:** Frozen (confirmed 2026-09-22 after 2 review rounds; user authorized implementation)

**Origin:** user request — Save button relocated (sticky bottom bar, per user's acceptance of the reviewer's recommendation over a floating button); an Edit action added; handover note moves into the edit screen; edit screen has Save and Delete; edit screen follows the app's general edit-screen convention.

**What already exists today (unchanged unless noted):**

- Handover note: currently an inline `TextField` + inline `FilledButton` ("Save absence") on the **display** screen (`away_plan_handover_note_section.dart`), calling `updateHandoverNote`.
- Carer assignment: an edit-icon-per-row opening `AwayPlanCarerEditDialog` (`away_plan_carer_edit_dialog.dart`) — **out of scope for this change.** Nothing was asked about this flow and it isn't the "Save absence" button under discussion; it stays exactly as-is, inline on the display screen. Flagging explicitly so scope doesn't silently expand.
- Absence dates / pet list: there is **no existing edit capability** for these today — `PlannedAbsenceFlowScreen` (`/pc/away/new`) is create-only (`createPlannedAbsence`, no `absenceId` param, no update call). Editing dates/pets was not requested and isn't being added here; it stays a gap, unchanged by this plan.
- Delete: there is **no hard-delete endpoint**. `POST /api/planned-absences/:id/cancel` already exists (`server/routes/careContext/plannedAbsencesRouter.js`) and does the soft-delete this app already models (`status: 'cancelled'`, `cancelled_at`), consistent with D-AWAY-001's two-state status model. A cancelled absence is already read-only server-side (`Cannot edit a cancelled absence`, line 331). **"Delete" in the edit screen calls this existing endpoint** — no new backend delete semantics.

**New edit screen** (`/pc/away/:id/edit`, mirrors the existing `/pc/away/new` / `/pc/away/:id` naming from AW-2):

- Scope: **handover note** (moved from display) + **Delete** (new UI, existing backend). Nothing else — see scope boundary above.
- Follows the app's established edit-screen convention (`AppFormStickyActionsBar`, `AppFormDestructiveButton`, `PopScope` + `confirmDiscardFormChanges`, `AppFormBreakpoints` phone/tablet split — as used in `vet_form_screen.dart`, `pet_form_screen.dart`). Save sits in the sticky bottom bar (phone) / inline actions row (tablet); Delete is a separate `AppFormDestructiveButton` within the form body, gated by a confirm dialog — not adjacent to Save.
- Delete confirmation dialog explains this cancels the whole absence plan (not a single pet or carer) and is not reversible from the UI.
- On successful delete, navigate back to the Away Plan hub (`/pc/away`), consistent with how cancelled absences already behave elsewhere (hub excludes/greys cancelled entries — verify at implementation, no change intended here).

**Display screen changes:**

- Remove the inline note `TextField` + inline Save button.
- Show the handover note **read-only** when present (not hidden) — a returning pet parent or (if ever given access) a carer should still see it without entering edit mode.
- Add an "Edit" `IconButton` in the app bar, next to the existing PDF-download icon, navigating to the new edit screen. Disabled when `absence.isCancelled` (same guard the download button already uses).
- No Save button remains on the display screen (repository's "Save is only in the edit screen" requirement).

**Button placement (user accepted the reviewer's recommendation):** no floating/FAB button. Sticky full-width bottom bar on phone (`AppFormStickyActionsBar`), inline row on tablet — the existing convention, not a new one.

**(added per review round 1) Accepted UX asymmetry:** carers stay editable inline on the display screen (edit-icon-per-row dialog) while the note and delete require entering the new edit screen. This is a deliberate, scope-honest split — not an oversight — because carer editing wasn't part of the original request and changing it would touch an already-shipped, tested flow. Flagging it here so it reads as a documented trade-off rather than an inconsistency, should it come up in review or user feedback later.

---

## Related

- [away-planning-decisions.md](./away-planning-decisions.md) — D-AWAY-001 (status model), D-AWAY-002 (readiness presentation — partially superseded, see D-AWD-001), D-AWAY-004 (`note_only` carer has no app access), D-AWAY-006 (collapse rule — superseded, see D-AWD-002), D-AWAY-007 (indeterminate visibility — extended, see D-AWD-003)
- [away-planning-delivery-plan.md](./away-planning-delivery-plan.md) — V1 sequencing this iterates on
- [away-plan-detail-v2-delivery-plan.md](./away-plan-detail-v2-delivery-plan.md) — phase sequencing for this plan
- `docs/design/design.mdc` — "reassure when facts support it" (tension with D-AWD-001, resolved as: no line shown reads as fine, not as silence)
- `.cursor/rules/testing.mdc`, `flutter-mobile.md` protocol — edit-screen conventions cited in D-AWD-007
