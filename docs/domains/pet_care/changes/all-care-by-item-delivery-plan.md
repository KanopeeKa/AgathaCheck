---
title: All care by care item — delivery plan
owner: Product / Documentation
audience: both
status: active
last_updated: 2026-11-10
tags: [pet_care, care_item, execute-plan]
---

# All care by care item

**Programme:** execute-plan `all-care-by-item-c455`  
**Outcome:** One All care screen (`/pc/events`). Each care item is a card whose lines are its care dates, grouped into Today, Upcoming, Paused care, and Closed care, with pet filtering via chips.

**Navigation (locked):** bottom tab **Care** (FR **Soins**); screen title **All care** (FR **Tous les soins**). Away-plan list rows unchanged. `/o/events` shares the card component; **not** a Pre-UAT release gate.

---

## 1. Surfaces

| Surface | Shows | Pet name on cards |
|---|---|---|
| All care (`/pc/events`, main navigation tab) | All four sections, pet chips, filters | Yes, always |
| Pet screen, "{Pet}'s care" | Today and Upcoming for that pet (Upcoming capped at 5 cards), plus always-visible "View all care" | No |
| Dashboard | Today for all pets, plus link to All care | Yes |

- `/pet/:petId/events` redirects to `/pc/events?pet=<id>` (preserves `returnTo` when present).
- Care details stays at `/pet/:petId/events/:entryId`.
- "View all care" opens All care with that pet's chip selected.
- Organisation list (`/o/events`) uses the same cards and sections; org filter bar unchanged except pet/status/skipped removals on the Pet Care list.

## 2. Pet chips and filters

- Chip row: **All pets** plus one chip per pet; horizontally scrollable; multi-select. **All pets** clears selection.
- Selection in address: `?pet=<id>` (repeatable).
- From a pet: pre-select chip; **Back** uses existing `shell_return_navigation` `returnTo`; tab entry has no special back behaviour.
- Filter panel: ownership, category, group, recurrence only (pet on chips; status and **Show skipped** removed).
- Chips and filters apply to all four sections and Paused/Closed counts.
- App bar **+** pre-selects pet when exactly one chip is selected.

## 3. Sections

| Section | Holds | Order | Default |
|---|---|---|---|
| Today | Active care with overdue, date today, or completed today | Oldest open date first; cards with no open dates last | Open |
| Upcoming | Other active care | Next date first; no date last | Open |
| Paused care (N) | Paused | Most recently due first | Collapsed |
| Closed care (N) | Closed (any reason) | Closed by you first, then most recent | Collapsed |

Empty Today keeps title and **Nothing due today**. Paused/Closed hidden when empty. **Today** uses each pet's home timezone.

Removed: Morning/Afternoon/Evening, Due soon (7d), collapsed Upcoming toggle, same-day sub-headings, multi-pet coordination line, Closed care footer link, **Other care** section.

## 4–8. Card, lines, pills, interactions, states

Per product review (2026-11-10): card header (family icon, title, `pet · category · schedule`, chevron); date lines with pill left and tick in a fixed right column; paused/closed header-only cards with grey pills per #2215.

Line rules: single overdue → dated Overdue + tick; 2+ overdue → `{n} not recorded` + chevron (neutral grey); today lines in time order; next future line when no open today line remains; tick uses D-CIE-030 with **list line** carve-out (tick completes that line when the line names the date).

Loading: skeleton (phase 4). Filtered empty: **No care matches these filters** + **Clear filters**.

## 9. Accessibility and test ids

- Card header **≥56** logical px; each date line **≥48**; tick **48×48** (documented deviation from legacy 56px single-row rule).
- Section ids: `care_list_today`, `care_list_upcoming`, `care_list_paused_toggle`, `care_list_closed_toggle`.
- Card/chip ids per spec review (`care_card_*`, `care_list_pet_chip_*`).
- Migrate E2E per phase for the surface touched; dashboard/pet scenarios stay on old ids until phase 5.

## 10. Data

Per care item, additive list **completionsToday**: `{ occurrenceId, scheduledTime?, completedOn }[]` for dates completed today (server-authoritative; pet home timezone).

## 11. Phasing (execute-plan)

| Phase | Outcome |
|-------|---------|
| 1 | Pet chips + `?pet=` on `/pc/events`; Paused/Closed collapsible blocks; **Planned** rows in canonical docs; proposal lives here |
| 2 | Pet route redirect; remove standalone pet All care; rename tab/screen; drop status/skipped filters (interim: old rows + Due soon remain) |
| 3 | API `completionsToday` field (no client history fallback) |
| 4 | Care-item cards; Today/Upcoming on `/pc/events`; skeleton loading; migrate `/pc/events` E2E |
| 5 | Pet screen + dashboard adoption; badge rewiring; retire agenda rows on those surfaces; E2E for dashboard/pet |

## 12. Supersedes (canonical updates)

- `care-item-evolution.md`: CARE-ITEM-R-003, R-004, R-012; D-CIE-025, D-CIE-026, D-CIE-035; D-CIE-029 (lists); D-CIE-030 line-tick carve-out; D-CIE-038 for card list order.
- `care-status-model.md`: R-021, R-024 naming; UX surfaces for in-list Paused/Closed.
- `terminology.md` D38: tab **Care**, screen **All care**, link copy alignment.

## 13. Proof on UAT

1. Open Pet Care → tab **Care** → **All care** with chips.
2. From a pet profile, **View all care** → chip selected; back returns when `returnTo` set.
3. Tick an open today line → snackbar **Done · Undo**; card lines update after server confirm.
4. Paused/Closed collapsed sections expand to header-only grey-pill cards.

---

## Open questions (closed)

1. Line tick with older unrecorded: tick completes named line (D-CIE-030 carve-out).  
2. Count line: neutral grey.  
3. No cap on today lines v1.  
4. Dashboard: Today only.  
5. Pet screen Upcoming: first 5 cards.  
6. Remove `/pc/events` subtitle.
