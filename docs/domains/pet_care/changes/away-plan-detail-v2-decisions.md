---
title: Away Plan Detail V2 — Decision log
owner: Product / Agent
audience: both
status: proposed
last_updated: 2026-09-22
tags: [pet_care, care_context, away_planning, decisions]
---

# Away Plan Detail V2 — Decision log

Proposed product and engineering decisions for **Away Plan Detail V2** — a redesign of the Away Plan detail screen (`PlannedAbsencePlanScreen`, `/pc/away/:id`) shipped in **Away Planning V1** ([away-planning-decisions.md](./away-planning-decisions.md), confirmed 2026-09-15, all phases merged).

**Status: Proposed — pending review.** Nothing below is Frozen yet. This document is the artifact to review before `approve-autonomous away-plan-detail-v2` (see [execute-plan schema](/docs/agent-efficiency/execute-plan-schema.md)). Decisions that supersede a V1 decision are called out explicitly; V1 decisions not mentioned here are unchanged.

**Context:** AgathaTrack is not in production; no real user data exists. Verified against `main` (post Away Planning V1, all AW-phases merged, plus Care Schedule Management V1 and Care Family icon work).

---

## D-AWD-001 — Plan-page readiness becomes attention-only (supersedes part of D-AWAY-002)

**Status:** Proposed

**Origin:** user request — "Remove the text warning/description for Carer Coverage and Care coverage. It is not necessary as it's clear in the fields below." Reviewed and narrowed: full removal would drop the "reassure and stop" behaviour that `design.mdc` calls out as a voice principle, and that D-AWAY-002 built for exactly this reason. Compromise: keep the fact, drop the line when it isn't actionable.

**Rule (plan page only — `AwayPlanHeaderSection`):**

- **Carer coverage** line renders only when `readiness.carerCoverage.state != all_have_carers` (i.e. some or none have a carer). When all pets have a carer, render nothing — the per-pet carer cards below already say so.
- **Care coverage** line renders only when `readiness.careCoverage.coverageState` is `has_items_to_review` or `indeterminate`. The reassuring states (`nothing_scheduled`, `all_completed`, `no_unresolved_items`) render nothing — the per-pet "Planned care" cards below already carry that detail (D-AWD-002/003 below).
- Both lines keep their existing copy (`AwayPlanCopy.carerCoverageSummary` / `careCoverageSummary`) when shown — no new wording, no icon/severity styling added in this pass (out of scope; a colour/severity treatment is a natural follow-up, not bundled here).
- **Not changed:** the dashboard tile's fixed-priority readiness rule (D-AWAY-002 §Dashboard tile) and the handover PDF's carer/care coverage section — the PDF is read by someone with no "fields below" to check against, so it keeps both lines unconditionally. Revisit PDF wording only if review asks for it.

**Rejected:** removing the lines entirely (loses the "am I covered?" answer above the fold); keeping them unconditionally (redundant with the sections below in the common case, which was the original complaint).

---

## D-AWD-002 — Care events are grouped by health entry, not by time slot, across all frequencies (supersedes D-AWAY-006's grouping key)

**Status:** Proposed

**Origin:** user request to replace the "Dated care" vs "Indeterminate care" split with one "Planned care" list: icon + title, then `Occurs every X (or single care) from A until B`, `Next due date` (only for once-per-day events), and a `Time of day` line per distinct time.

**Current state (`server/lib/recurrenceHelper.js#splitRoutineAndDatedItems`):** only `frequency === 'daily'` entries collapse, keyed by `health_entry_id + scheduled_time` — a twice-daily medication produces **two** routine rows today, not one row with two times. Every other frequency (`weekly`, `monthly`, `yearly`, `custom`) is left as individual per-occurrence "dated" rows, with no recurrence metadata surfaced.

**New rule:**

- Group by `health_entry_id` **only** (drop the time-slot key), for **every** repeating frequency (`daily`, `weekly`, `monthly`, `yearly`, `custom`) — not just `daily`.
- A group carries: `name`, `type`, `care_family`, `frequency`, `frequency_interval`, distinct `times_of_day: string[]` (sorted, deduped across constituents; empty array = all-day/untimed), `occurrence_count`, `status_counts`, `first_scheduled_date`, `last_scheduled_date`, and `certainty` — **unchanged from D-AWAY-006:** minimum certainty among constituents (`conditional_on_future_completion` anywhere in the group ⇒ group renders as `~`).
- **`frequency === 'once'` entries are never grouped.** Each stays its own row, one per occurrence — user's explicit call: *"for dated occurrence -> show them all in a list."* These map 1:1 to today's individual dated rows; only their on-screen template changes (D-AWD-003).
- `next_due_date` (earliest **pending** occurrence date in the projected window) is computed **only when `times_of_day.length <= 1`** — i.e. the event fires at most once per calendar day. Omitted (`null`) when `times_of_day.length > 1`, per the user's explicit rule: *"if it's an event that happens multiple times a day every day, don't show that line."*

**Not in scope:** changing Care Schedule Management's projection engine (`server/lib/care/schedule/projectSchedule.js`) or occurrence materialisation. This is a read-side regrouping in `recurrenceHelper.js` / `server/lib/care/awayPlan/presentation.js` only — the underlying occurrence data (source of truth) is untouched. Projection corpus for CSM itself must stay byte-identical, same guarantee V1's AW-3 made.

---

## D-AWD-003 — Completion-chain (indeterminate) items get an interval description, not just a reason code (extends D-AWAY-007)

**Status:** Proposed

**Origin:** user request — indeterminate/chain-dependent items ("waiting on a prior dose") still have a recurrence rule, e.g. "every 10 days from the last occurrence"; that's what should render, plus one explanatory line at the bottom of the plan.

**Rule:**

- When an uncertain entry has a repeating `frequency` (not `once`), the unified row still shows an "occurs every" line, but anchored to the **last known occurrence** instead of a calendar date range: *"Occurs every {interval} {unit} from the last occurrence"* (exact copy in D-AWD-004's ARB keys) — never a fabricated calendar date, never `next_due_date` (omitted unconditionally for chain-anchored items, regardless of `times_of_day`).
- When the entry is a genuinely indeterminate one-off (`frequency === 'once'`, pending on a prior chain step — no interval exists at all), fall back to today's reason copy (`awayPlanningIndeterminatePending` / `…Chain` / `…Generic`) — unchanged.
- The plan page adds **one static explanatory line**, rendered once per pet-care section (not per row) when at least one visible event in that pet's list is chain-anchored — not per row, to avoid repeating the same caveat next to every affected event. Placement: bottom of the "Planned care" card, below the event list. Exact copy TBD at implementation (new ARB key, e.g. `awayPlanningChainAnchorExplainer`), reviewed for tone against `docs/design/copy-tone.md`.
- **`anchor_kind: 'calendar' | 'completion_chain'`** is added to the wire contract so the client can decide which explainer/next-due rule applies without re-deriving it from `certainty`/`reasonCodes` client-side (keeps derivation server-side, consistent with D-AWAY-001's "facts computed server-side at read time" principle).

---

## D-AWD-004 — One unified "Planned care" list replaces Routine / Dated / Indeterminate sections

**Status:** Proposed

**Rename:** "Dated care" → **"Planned care"** (`awayPlanningScheduleDatedTitle` copy key repurposed as the single section heading; `awayPlanningScheduleRoutineTitle` and `awayPlanningScheduleIndeterminateTitle` retire as section headings — the distinction moves into per-row copy, not separate headings).

**Row template** (applies uniformly to grouped-recurring, one-off dated, and chain-anchored items from D-AWD-002/003):

```
[CareFamilyIcon]  {event title}
                   {schedule line — one of:}
                     "Occurs every {interval} {unit} from {first} until {last}"      (recurring, calendar-anchored)
                     "Occurs every {interval} {unit} from the last occurrence"        (recurring, completion-chain-anchored)
                     "Single care on {date}"                                          (frequency = once)
                     "{indeterminate reason}"                                         (once, chain-pending, no interval)
                   "Next due date: {date}"                                            (only when times_of_day.length <= 1 AND calendar-anchored)
                   "Time of day: {time}"  × N                                         (one line per distinct time_of_day, only when present)
```

Icon: `CareFamilyIcon.materialIconFor(CareFamily.fromWire(item.careFamily))` (`flutter_app/lib/features/pet_profile/presentation/widgets/care_family_icon.dart`) — replaces the current hardcoded `Icons.repeat` / `Icons.check_circle_outline` / `Icons.help_outline` per-bucket icons. This is a **reuse**, not a new icon system.

**Not shown per row any more:** the old per-occurrence completed/skipped/pending status glyph on dated rows. Trade-off flagged and accepted by the user: the plan page becomes a forward-looking schedule view; occurrence-level completion tracking is one tap away (D-AWD-005) rather than duplicated inline.

---

## D-AWD-005 — Care events are tappable; navigation reuses the existing Care Item Detail screen

**Status:** Proposed

**Origin:** user request — "clicking on one event should take you to the event itself — where carer will be able to see history and upcoming occurrences."

**Rule:** each unified care-event row is a single tap target (whole row, ≥48×48, per `design.mdc` touch rule) navigating to the existing route `petEventView` → `/pet/:petId/events/:entryId` (`CareItemDetailScreen`). `petId` is already in scope in `AwayPlanPetCareSection`; `entryId` is `item.healthEntryId`, already present on every item type (`CarePeriodRoutineItem`, `CarePeriodProjectionItem`, `CarePeriodUncertainty`). **No new screen, no new route.**

**Authorization:** unchanged. Anyone viewing the away plan already holds the `pet_access` that `CareItemDetailScreen` itself requires. `note_only` carers have no app access at all (D-AWAY-004) and never reach either screen — this tap-through creates no new exposure.

---

## D-AWD-006 — Pet header gets a photo + tap-through to the pet profile

**Status:** Proposed

**Origin:** user request — "would be nice to add the pet profile picture next to its name + link to the pet screen."

**Rule:** `AwayPlanPetCareSection`'s per-pet header gets a 32px circular pet photo left of the pet name, reusing the existing `CareEventRowPetAvatar` pattern (`buildPetPhotoOrPlaceholder`, `flutter_app/lib/features/health_tracking/presentation/widgets/care_event_row_pet_avatar.dart`) — not a new avatar component. The header row becomes a single tap target navigating to the existing `petDetail` route → `/pet/:petId` (`PetDetailScreen`).

Applied to `AwayPlanCarersSection`'s per-pet row too, in the same phase, since it's the identical widget with no new logic — bundling avoids a near-duplicate follow-up PR for one extra call site.

---

## D-AWD-007 — Plan page becomes read-only; a new edit screen owns writes

**Status:** Proposed

**Origin:** user request — Save button relocated (sticky bottom bar, per user's acceptance of the reviewer's recommendation over a floating button); an Edit action added; handover note moves into the edit screen; edit screen has Save and Delete; edit screen follows the app's general edit-screen convention.

**What already exists today (unchanged unless noted):**

- Handover note: currently an inline `TextField` + inline `FilledButton` ("Save absence") on the **display** screen (`away_plan_handover_note_section.dart`), calling `updateHandoverNote`.
- Carer assignment: an edit-icon-per-row opening `AwayPlanCarerEditDialog` (`away_plan_carer_edit_dialog.dart`) — **out of scope for this change.** Nothing was asked about this flow and it isn't the "Save absence" button under discussion; it stays exactly as-is, inline on the display screen. Flagging explicitly so scope doesn't silently expand.
- Absence dates / pet list: there is **no existing edit capability** for these today — `PlannedAbsenceFlowScreen` (`/pc/away/new`) is create-only (`createPlannedAbsence`, no `absenceId` param, no update call). Editing dates/pets was not requested and isn't being added here; it stays a gap, unchanged by this plan.
- Delete: there is **no hard-delete endpoint**. `POST /api/careContext/plannedAbsences/:id/cancel` already exists (`server/routes/careContext/plannedAbsencesRouter.js`) and does the soft-delete this app already models (`status: 'cancelled'`, `cancelled_at`), consistent with D-AWAY-001's two-state status model. A cancelled absence is already read-only server-side (`Cannot edit a cancelled absence`, line 331). **"Delete" in the edit screen calls this existing endpoint** — no new backend delete semantics.

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

---

## Related

- [away-planning-decisions.md](./away-planning-decisions.md) — D-AWAY-001 (status model), D-AWAY-002 (readiness presentation — partially superseded, see D-AWD-001), D-AWAY-004 (`note_only` carer has no app access), D-AWAY-006 (collapse rule — superseded, see D-AWD-002), D-AWAY-007 (indeterminate visibility — extended, see D-AWD-003)
- [away-planning-delivery-plan.md](./away-planning-delivery-plan.md) — V1 sequencing this iterates on
- [away-plan-detail-v2-delivery-plan.md](./away-plan-detail-v2-delivery-plan.md) — phase sequencing for this plan
- `docs/design/design.mdc` — "reassure when facts support it" (tension with D-AWD-001, resolved as: no line shown reads as fine, not as silence)
- `.cursor/rules/testing.mdc`, `flutter-mobile.md` protocol — edit-screen conventions cited in D-AWD-007
