---
title: Spec — Care Item bulk actions show their scope
owner: Product / Agent
audience: both
status: draft
last_updated: 2026-10-05
tags: [pet_care, care_item, ux, accessibility]
---

# Spec — Care Item bulk actions show their scope

Status: draft, ready for product sign-off on §9. ·
Surface: Flutter only (`flutter_app/lib/features/care_item/presentation/detail/**`,
`flutter_app/lib/core/widgets/care_mark_done_button.dart`, l10n EN/FR). No server change.

Related: [`not-recorded-stale-open-bug-spec.md`](not-recorded-stale-open-bug-spec.md) (FR-6,
FR-7, AC-E1–E6, §6 Q4). This spec changes how that spec's bulk actions are **presented and
labelled**. It does not change what they do.

## 1. Problem

On the Care Item view, the **Needs attention** module lists every open dose in one list: Not
recorded (open), Overdue, Due and Coming up. Under the whole list sit **Mark all as done** and
**Skip all**.

Users read "all" as "every row above". The commands actually act only on doses that have
**started** (overdue, open not recorded, and due once their time has passed). Coming up doses
stay open. For a medication course, that makes users think they closed doses they did not, or
fear they closed next week's doses.

Three things make it worse:

1. **Position.** The buttons sit under the whole list, including every Coming up row, so the
   buttons look like they apply to all of it. On a long course the Coming up rows also push
   the buttons far down.
2. **Wording.** "all" with no count or scope.
3. **The tick control looks like a checked checkbox.** Every row shows a filled square with a
   checkmark, so every row looks already selected.

Two further defects on the same rows:

4. Every row's tick has the same screen-reader label ("Mark {item} as done"), so screen-reader
   users can't tell which dose a tick acts on.
5. A Coming up dose days away has the same primary tick as an overdue one, which invites a
   wrong tap on a medication.

## 2. Outcome

**The bulk actions on the Care Item view act on exactly the rows shown directly above them,
and their labels say how many.** Coming up doses are visibly separate and have no bulk or
inline actions.

## 3. Scope

**In scope**
- The schedule-based **Needs attention** module (`CareItemNeedsAttentionSection`).
- The shared mark-done control's icon and shape (`CareMarkDoneButton`, see D3).
- Bulk snackbar copy (FR-7 alignment).
- Wording updates to the bug spec's FR-6 and AC-E1–E3 (§10).

**Out of scope (non-goals)**
- Any change to bulk command semantics, the server, or the stack rule (D-CIE-034).
- Checkboxes, selection mode, or partial bulk selection. Possible follow-up; see §11.
- `CareItemDatesSection` (items with no schedule, or paused). It keeps its own layout. Its
  "Skip all overdue" button is tracked as a follow-up for count-based copy (§11).
- Closed Not recorded doses (bug spec FR-3/FR-5, Q3).

## 4. Definitions

| Term | Meaning |
|---|---|
| **Started dose** | An open dose for which `occurrenceHasStarted` is true at the schedule's `asOf`: Overdue, Not recorded (open), or Due whose time has passed (or Due with no time). |
| **Later today** | A Due dose whose time has not yet passed. Not started. |
| **Coming up** | An open dose on a future day. Not started. |
| **Attention group** | The started doses, shown together at the top of the module. |
| **Upcoming group** | Later today + Coming up doses, shown below the attention group. |
| **Bulk scope** | Exactly the doses listed in the attention group at the moment the user taps. |

## 5. Target layout

```
┌ Needs attention ─────────────────────────────── (module title) ┐
│ Oct 2, 2026 · 08:00   (Not recorded)            (✓)  (⏭)       │
│ Oct 2, 2026 · 20:00   (Overdue)                 (✓)  (⏭)       │
│ Oct 5, 2026 · 08:00   (Due)                     (✓)  (⏭)       │
│                                                                │
│ [ ✓ Mark 3 as done ]          [ ⏭ Skip 3 ]                     │
│ ───────────────────────────────────────────────────────────── │
│ Coming up                                                      │
│ Oct 5, 2026 · 20:00   (Later today)                     ›      │
│ Oct 7, 2026 · 08:00   (Coming up)                       ›      │
│ Show 5 more                                                    │
│ Estimated next: …  (unchanged, when present)                   │
└────────────────────────────────────────────────────────────────┘
```

`(✓)` = Mark done icon button (filled). `(⏭)` = Skip icon button (outlined). `›` = row opens
the occurrence screen (existing behaviour; no new control required).

## 6. Functional requirements

### Grouping and order

**FR-1 — Two groups.** The module shows the **attention group** first, then the **upcoming
group**. A dose appears in exactly one group, decided by `occurrenceHasStarted` (§4).

**FR-2 — Attention group order.** Earliest first (same order as `startedOccurrences`). Each row
keeps its existing status pill (Not recorded (open) / Overdue / Due), so states stay distinct
by label and icon, not colour alone.

**FR-3 — Upcoming group.** Has its own heading "Coming up" and a visual separator from the
attention group. Rows are earliest first. A Later today row shows a **Later today** pill; a
future-day row shows **Coming up**.

**FR-4 — Upcoming is capped.** The upcoming group shows at most **2** rows. If there are more,
a **Show {n} more** control expands the rest inline (and becomes **Show less**). Default is
collapsed on every visit.

**FR-5 — Empty groups.**
- No started doses: the attention group and the bulk buttons are not shown. The module title
  and upcoming group still show.
- No upcoming doses: the upcoming group (heading included) is not shown.
- Both empty: existing behaviour for that state is unchanged.

**FR-6 — Estimated next.** The estimated next date subtitle (AID-10) stays, placed after the
upcoming group.

### Row actions

**FR-7 — Started rows have Mark done and Skip.** Each attention-group row shows two icon
buttons: **Mark done** then **Skip**. Mark done uses the existing done flow
(`careCompletionFlowProvider.done`, including its DN rules and confirmations). Skip uses the
existing single-dose skip command.

**FR-8 — Skip feedback.** A successful row Skip shows the snackbar "{name} skipped", with Undo
when the command returns an undo token. Failures use the existing messages ("Already updated",
command failed).

**FR-9 — Upcoming rows have no inline actions.** No Mark done, Skip or checkbox on Later today
or Coming up rows. Tapping the row opens the occurrence screen, where early completion (with
the existing DN-4 confirmation) and skip remain available, so bug spec FR-2 still holds.

**FR-10 — Row tap unchanged.** Tapping a row outside its buttons opens the occurrence screen,
as today.

### Bulk actions

**FR-11 — Position.** The bulk buttons sit **directly under the last attention-group row** and
**above** the upcoming group. They are never placed below upcoming rows.

**FR-12 — When shown.** Bulk buttons show only when the attention group has **2 or more** rows
(the stack rule, D-CIE-034) and the module is not muted. With exactly one started dose, see
D2.

**FR-13 — Labels carry the count.** Labels are **Mark {count} as done** and **Skip {count}**,
where `count` equals the number of rows in the attention group. The word "all" is not used.
Proper plural forms in EN and FR.

**FR-14 — What you see is what is sent.** The dose IDs sent to `resolveStack` are exactly the
attention-group rows on screen when the user taps. If the screen refreshes (pull to refresh,
return to the screen, a command finishing) groups and counts are recomputed before the next
tap.

**FR-15 — Equal weight, distinct emphasis.** The two buttons sit side by side at equal width:
Mark done **filled** (primary), Skip **outlined** (secondary), same height and shape, each with
icon + text. When both labels can't fit on one line (narrow width or large text scale), they
stack vertically, Mark done first, both full width.

**FR-16 — Busy state.** While a bulk command runs, both bulk buttons and all row buttons are
disabled, and a second tap does nothing.

**FR-17 — Bulk feedback carries the count (bug spec FR-7).** On success the snackbar always
states the number changed:
- all changed: "{count} marked done" / "{count} skipped"
- some already closed: existing "{changed} marked done · {ignored} already closed" /
  "{changed} skipped · {ignored} already closed"

One Undo reverts exactly the doses this command changed (bug spec AC-E5). Nothing-to-update
and failure keep the existing messages ("Already updated", command failed).

### Icons and controls

**FR-18 — Mark done icon.** `check_circle` (filled variant on the filled bulk button and on
the row icon button's filled style). The control is **round**, not a square, so it can't read
as a ticked checkbox.

**FR-19 — Skip icon.** `skip_next`, matching how skipped doses already appear in
administration history. `close`, `remove_circle_outline`, `block` and `do_not_disturb` are not
used for Skip.

**FR-20 — Theme tokens only.** Colours, shapes and sizes come from theme tokens and shared care
primitives; no one-off colours.

### Copy and l10n

**FR-21 — Strings (EN; FR to match).**

| Key purpose | EN |
|---|---|
| Bulk mark done | Mark {count} as done |
| Bulk skip | Skip {count} |
| Bulk done snackbar | {count} marked done |
| Bulk skip snackbar | {count} skipped |
| Upcoming heading | Coming up (reuse `occurrenceZoneComingUp`) |
| Later today pill | Later today |
| Expand / collapse | Show {count} more / Show less |
| Row mark done (a11y) | Mark {date time} as done |
| Row skip (a11y) | Skip {date time} |

`careMarkAllDone` and `careSkipAll` are no longer used on this surface. Remove them if no other
surface uses them.

### Accessibility

**FR-22 — Each control names its dose.** Row Mark done and Skip buttons have semantic labels
and tooltips that include the dose's date and time, e.g. "Mark Oct 2, 2026, 20:00 as done",
"Skip Oct 2, 2026, 20:00".

**FR-23 — Group headings are headings.** "Needs attention" and "Coming up" are exposed as
headings, so screen-reader users can jump between them.

**FR-24 — Bulk scope is in the label.** The bulk buttons' accessible names are their visible
text (with the count). No information is conveyed by position or colour alone.

**FR-25 — Targets and focus.** Every interactive control is at least 48×48 dp. Focus order per
row: row → Mark done → Skip. After the attention rows: Mark {n} as done → Skip {n} → upcoming
group. Focus is visible on every control.

**FR-26 — Text scale.** At 200% text the layout doesn't overflow or clip: rows wrap, bulk
buttons stack (FR-15).

## 7. Acceptance criteria

Fixture unless stated: Fixed-schedule item, twice daily, `asOf` = Oct 5, 14:00.

### A. Grouping

- **AC-A1** Given open doses Oct 2 08:00 (Not recorded), Oct 2 20:00 (Overdue), Oct 5 08:00
  (Due), Oct 5 20:00, Oct 7 08:00, the attention group lists the first three in that order,
  and the upcoming group lists Oct 5 20:00 (pill "Later today") and Oct 7 08:00 (pill "Coming
  up").
- **AC-A2** A Due dose whose time has passed is in the attention group; a Due dose whose time
  has not passed is in the upcoming group. A Due dose with no time is in the attention group.
- **AC-A3** Not recorded (open) and Overdue rows in the same group keep distinct pills (label
  and icon).
- **AC-A4** Given 7 upcoming doses, 2 show plus "Show 5 more". Tapping it shows all 7 and
  "Show less". Leaving and returning shows 2 again.
- **AC-A5** Given 2 upcoming doses, no Show more control appears.
- **AC-A6** Given no started doses, no attention rows and no bulk buttons appear; the upcoming
  group shows.
- **AC-A7** Given no upcoming doses, no "Coming up" heading appears.
- **AC-A8** The estimated next subtitle, when present, appears after the upcoming group.

### B. Row actions

- **AC-B1** Every attention-group row shows a Mark done and a Skip button; no upcoming row
  shows either, nor any checkbox.
- **AC-B2** Tapping Mark done on a started row runs the existing done flow for that dose only.
- **AC-B3** Tapping Skip on a started row skips that dose only and shows "{name} skipped" with
  Undo when available; Undo reopens it.
- **AC-B4** Tapping an upcoming row opens its occurrence screen, where Mark done (with the
  DN-4 confirmation when more than half an interval early) and Skip are available.
- **AC-B5** Tapping a row outside its buttons opens the occurrence screen.

### C. Bulk actions

- **AC-C1** *(replaces bug spec AC-E1 wording)* Given 3 started and 5 upcoming doses, the bulk
  buttons read "Mark 3 as done" and "Skip 3", sit directly under the third started row and
  above the "Coming up" heading. Tapping Mark 3 as done marks exactly those 3 done; all 5
  upcoming doses stay open.
- **AC-C2** Same as C1 for Skip 3.
- **AC-C3** Given exactly 1 started dose, no bulk buttons show (D2 decides what shows instead).
- **AC-C4** Given 0 started doses, no bulk buttons show.
- **AC-C5** No visible text on this module contains "all" for a bulk action, in EN or FR.
- **AC-C6** Given 3 started doses where 1 was closed elsewhere after the screen loaded, Mark 3
  as done shows "2 marked done · 1 already closed"; Undo reverts only those 2.
- **AC-C7** Given all started doses were closed elsewhere, the bulk command shows "Already
  updated" and the screen refreshes; no raw error appears.
- **AC-C8** On full success, the snackbar reads "3 marked done" / "3 skipped" (with the
  count), with Undo.
- **AC-C9** After a bulk command, the module refreshes; resolved doses leave the attention
  group and the counts on any remaining buttons are recomputed.
- **AC-C10** While a bulk command runs, a second tap on either bulk button or any row button
  does nothing.
- **AC-C11** When the screen refreshes and a Later today dose's time has passed, it moves into
  the attention group and the bulk count increases by one.

### D. Visuals and icons

- **AC-D1** Mark done controls (row and bulk) use `check_circle` and are round, not square.
- **AC-D2** Skip controls (row and bulk) use `skip_next`.
- **AC-D3** Bulk buttons are side by side at equal width, Mark done filled, Skip outlined. At
  360 dp width and 200% text they stack, Mark done first, with no overflow.
- **AC-D4** No hard-coded colours; light and dark themes both meet contrast for text and icons.

### E. Accessibility

- **AC-E1** A screen reader announces each row button with its dose, e.g. "Mark Oct 2, 2026,
  20:00 as done, button" and "Skip Oct 2, 2026, 20:00, button". No two buttons on the module
  share an accessible name.
- **AC-E2** "Needs attention" and "Coming up" are announced as headings.
- **AC-E3** Bulk buttons are announced as "Mark 3 as done, button" / "Skip 3, button".
- **AC-E4** Focus order follows FR-25; every control has a visible focus indicator.
- **AC-E5** Every interactive control is at least 48×48 dp.

### F. Localisation

- **AC-F1** All new strings exist in EN and FR, with plural forms for count strings (1 and
  many).
- **AC-F2** Dates in semantic labels use the same locale format as the visible row.

### G. Tests to add

- Widget tests for groups A1–A8, B1, C1–C5, C8, C10–C11, D1–D2, E1–E3 (mock completion
  service).
- Unit test: bulk snackbar message for full success (count) and partial (changed · ignored).
- Golden or layout test for D3 (360 dp, 200% text).
- BDD: update the Care Item stack scenarios for C1 ("Mark 3 as done" leaves Coming up open) and
  C3 (single started dose: no bulk). Keep `check_bdd_coverage.js` at or above the gate.

## 8. Edge cases

| Case | Expected |
|---|---|
| Item muted (paused/ended view) | No row or bulk buttons, as today |
| Flexible-schedule item with 2+ started doses | Same layout; bulk shown only if the stack rule says so (currently Fixed only) |
| Every dose started, none upcoming | Attention group + bulk; no "Coming up" heading |
| Very long course (30+ upcoming) | 2 shown + "Show 28 more" |
| Screen left open across a dose time | Groups update on the next refresh (AC-C11); the bulk command sends only what was on screen (FR-14) |
| Command conflict on a row action | Existing "Already updated" + refresh |

## 9. Product decisions

| # | Question | Recommendation |
|---|---|---|
| D1 | Heading of the attention group: keep the module title "Needs attention", or add a sub-heading "Overdue"? | Keep **"Needs attention"** as the only heading for started doses. It covers Due-now doses too; "Overdue" over a "Due" pill would be wrong. Row pills already show Overdue / Not recorded / Due. |
| D2 | With exactly one started dose, the current layout adds a large "Mark {name} as done" button, Reschedule and a ⋯ menu below the list. Keep it alongside the new row buttons? | Remove the large Mark done button (it duplicates the row button). Keep **Reschedule** and the **⋯** menu under the single row. |
| D3 | Change the mark-done icon only here, or in the shared `CareMarkDoneButton` (also used by agenda/care-surface rows)? | Change the **shared widget**. The checkbox look confuses on every surface, and one icon for one action keeps the app consistent. |
| D4 | Upcoming cap: 2 rows? | Yes. Enough to show what's next without pushing content down. |

## 10. Changes to the bug spec

In [`not-recorded-stale-open-bug-spec.md`](not-recorded-stale-open-bug-spec.md):

- **FR-6:** rename the actions to "the bulk Mark done / Skip actions (labelled with their
  count; see `care-item-bulk-scope-spec.md`)".
- **AC-E1–E3:** replace "Mark all as done" / "Skip all" with the count labels.
- **§6 Q4:** mark as decided: "started only, labelled with the count".

## 11. Follow-ups (track as issues)

- `CareItemDatesSection`: replace "Skip all overdue" with count-based labels and the same
  icons.
- Optional selection mode (checkboxes + bottom bar "Mark {n} as done / Skip {n}") if users ask
  for partial bulk. If done, checkboxes go on the left and never on upcoming rows.
- Design-system rule "scoped bulk": a multi-row care action states its scope by position and
  count, never an unqualified "all", and reports how many changed.

## 12. Delivery

One atomic PR: **"Care Item bulk actions act on exactly the rows above them and show the
count."** It covers FR-1 to FR-26, the bug spec wording (§10) and the tests in §7.G. Watch
file size: extract the row and the bulk bar into their own widgets to stay under 500 lines.
