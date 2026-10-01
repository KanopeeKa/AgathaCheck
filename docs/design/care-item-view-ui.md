---
title: Care Item view — UI modules
owner: Design Team
audience: both
status: active
last_updated: 2026-09-29
tags: [design, pet-care, care-item]
---

# Care Item view — UI modules

Canonical **visual** spec for the Care Item detail route (`/pet/:petId/events/:entryId`), the **care agenda** (dashboard, pet profile, All care), its row, the care sheets and the Create/Edit form's Advanced settings. Product copy and field rules remain in [care-item-evolution.md](../domains/pet_care/features/care-item-evolution.md).

## Intent

Operational **care desk** segmentation: warm page canvas, white module cards, clear action hierarchy. Calm — no decorative rainbow; severity uses shared semantic tokens + text.

## Decisions (2026-09-27)

| Topic | Decision |
|-------|----------|
| Relief | **Border-first** white modules on warm canvas; optional subtle shadow on web only (default off in v1) |
| Pet context | **Keep pet module** at top on mobile; compact chip in app bar on wide layouts (phase `web-layout`) |
| Icons | **Section headers + stat cells** only; not every metadata row |
| Absence | **`CareAttentionCallout`** tier when slice needs attention; hide section when no upcoming absence (spec open item) |
| Copy | No “View …” title; no “Current occurrence” (D-CIE-001) |

## Tokens (semantic)

| Role | Implementation |
|------|----------------|
| Page canvas | `AppColorTokens.petCareCollection` / `CareSurfaceTokens.collectionBackground()` |
| Module surface | `CareSurfaceTokens.moduleBackground()` (`neutral-50`) |
| Module border | `CareSurfaceTokens.moduleBorder()` |
| Module radius | `CareSurfaceTokens.collectionRadius` (16) |
| Hero inner radius | `CareSurfaceTokens.actionRadius` (12) |

Document hex values only in [`tokens.md`](./tokens.md) when promoted globally; Care Item v1 uses existing care-surface tokens.

## Module map (mobile order)

1. **Pet context** — existing `PetEventPetCard` inside `CareItemModule` (compact).
2. **Needs attention (hero)** — status pill + display date (`headlineSmall`) + care name secondary + **one** `FilledButton` (**Mark as done**, or **Review** for a Not recorded stack) + outlined **Change date**; occurrence menu (Skip, Postpone, Plan another date, Add note, Looked after by); occurrence rows inset inside module. Paused: "Paused since …" / "Paused until …" + Resume.
3. **Absence** — module or callout; resolution actions inside module body.
4. **Schedule** — header row with **Edit schedule** trailing; body = stat grid (Frequency · Type · Reminder) + prose lines (next date, flexibility).
5. **Details** — definition-list rows; **no duplicate recurrence** (schedule owns rhythm).
6. **History** — inset list (`CareCollectionInsetList` pattern) + **See full history** in module footer.

## Web (≥ `kCareItemTwoColumnBreakpoint`)

| Main column | Side column |
|-------------|-------------|
| Needs attention, Agatha (when present), History | Schedule, Absence, Details |

Pet context: side column top or header chip — implementation in `web-layout` phase.

## Components (Flutter)

| Widget | Path |
|--------|------|
| `CareItemModule` | `pet_care/.../care_surface/care_item_module.dart` |
| `CareItemSectionHeader` | `care_item_section_header.dart` |
| `CareItemStatCell` / `CareItemStatRow` | `care_item_stat_row.dart` |
| `CareItemDetailRow` | `care_item_detail_row.dart` |
| `CareItemStatusPill` | `care_item_status_pill.dart` |
| `CareItemDetailCanvas` | `care_item_detail_canvas.dart` |

## Acceptance (implementation)

- [ ] Modules use tokens; no ad-hoc `surfaceContainer*` on section roots
- [ ] Needs attention visually dominant; single primary CTA
- [ ] Overdue pill + text (D-CIE-006)
- [ ] Details omit repeated `formatRecurrenceSummary`
- [ ] Semantics headers preserved; actions ≥48dp
- [ ] Widget tests for new primitives

## Care agenda (D-CIE-025, D-CIE-026)

Same component on the dashboard (all pets) and the pet profile (one pet); All care uses the same groups.

| Part | Visual rule |
|------|-------------|
| Sections | **Today** · **Due soon** · **Upcoming** as `Semantics(header: true)` headings; Upcoming collapsed with a count and an expanded/collapsed state |
| Today | Overdue rows first; then **Morning / Afternoon / Evening / Anytime** sub-headings only when ≥ 2 groups have rows, otherwise one **Today's list** heading; done-today rows last, quiet (check + time) |
| Row | `CareActionRow` in `CareCollectionInsetList` (`system.md` §8.1): pet avatar (dashboard only) · name · `CareItemStatusPill` + date/time · **one** trailing button (Mark as done / Review). ≥ 56 visual height, whole row tappable, trailing button ≥ 48dp; merged label "Buddy, Flea treatment, Overdue, 5 June" |
| Status pill | Tones: coming up (neutral text) · due (warning) · overdue (error + urgency icon) · **notRecorded** (info + icon — new tone) · done (success + check) · skipped (neutral) · paused (neutral + pause icon). Colour never alone |
| Feedback | Button shows progress; the row changes only after the server responds; snackbar "Done · Undo" from the server result. No optimistic completion |
| Orientation | Dashboard line "2 overdue · 3 due today"; zero → "Nothing due today" |
| States | Skeleton while loading (no empty copy); error + Retry; no care → illustrated empty state + Add care |
| Motion | Row moves respect reduced motion |
| Not allowed | Progress bars, rings, "3 of 5", praise |
| Wide | Agenda in the main column, Today first; no side-by-side split of Today |
| Ids | `care_agenda_today`, `care_agenda_due_soon`, `care_agenda_upcoming`, `care_agenda_group_<morning\|afternoon\|evening\|anytime>`, `care_agenda_stack_<entryId>` |

## Care sheets

| Sheet | Layout |
|-------|--------|
| **When was this done?** (overdue) | Today · On the scheduled date · Choose another date; step 1 of the completion sheet |
| **Next date choice** (D-CSM-026) | Radio group: Keep {date} (pre-selected) · Skip {date} · Move this and following by {N}; checkbox "Remember my choice for this care item"; one primary **Save**; dismiss = Keep. Step 2 of the completion sheet when step 1 was shown |
| **Record earlier doses** | Per dose **Given / Not given** (medication) or **Done / Not done** (other care); footer "All given" / "None given" with the safe action first |
| **Early completion** | Dialog "Planned for 12 Mar. Mark it as done today?" · **Cancel** first · Mark as done |
| **Change date** | Date picker + radio **This date only** (default) / **This and following** (Fixed schedule) + preview of the next two dates + existing warnings |
| **Postpone until** | Date field + "No end date (pause)" switch + one-line consequence per schedule type |
| **Resume** | Date pre-filled with the default + "This is when it would have been" |
| **Plan another date** | Date (+ time for timed care); warning when within half an interval of another open date |

All strings in `app_en.arb` + `app_fr.arb`; focus visible; touch ≥ 48dp; `@smoke-a11y` axe scan on the agenda and every sheet.

## Create / Edit form — Advanced settings (D-CIE-027)

- **Main:** pet(s) · Plan something / Record something (segmented; switching hides and clears the other date) · category · name · dosage (medication) · repeat · Due date **or** Completed on (required) · vaccination "+ Add a booster date" (removable chips ≥ 48dp, "Remove booster date 1 Jul") · reminder · notes · health issue.
- **Advanced settings:** expandable header ≥ 48dp; one-line summary as subtitle and in the semantics label ("At home · Essential · After it's done · Ask me"); holds Where, Priority, **Schedule type** (Fixed schedule / After it's done + info sheet), **If done after the due date**, Provider, Documents. Auto-expands and focuses the first error on validation failure.

## Phased delivery

Care occurrences programme (`care-next-occurrence-c1a7`): agenda, row and sheets in child C; form and Care Item view actions in child D.


Execute-plan `care-item-view-ui`: design → primitives → needs-attention → schedule-absence → details-history → web-layout → header-wayfinding → integration-main.
