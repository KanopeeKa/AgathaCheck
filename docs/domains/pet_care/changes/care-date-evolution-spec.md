---
title: Care date screen evolution (proposed)
status: in-delivery
status_since: 2026-10-08
folds_into: docs/domains/pet_care/features/care-item-evolution.md
plan: care-date-evolution-b20d
---

# Care date screen evolution

**Status:** proposed — folds into `care-item-evolution.md` in execute-plan phase 3.

## Layout

| Order (phone + wide) | Module |
|----------------------|--------|
| 1 | Occurrence identity (family chip + pet rail left; schedule actions under datetime on right) |
| 2 | Away (when in window) |
| 3 | Complete (weight if required + Mark as done only when open) |
| 4 | Next open (when successor exists) |

## Decisions (target IDs on canonical fold)

| ID | Decision |
|----|----------|
| D-CIE-037 | Care date is the canonical leaf for confirming one occurrence; Care item rows are shortcuts |
| D-OSM-013 | Phone module order matches wide: Away before Complete |
| D-OSM-014 | Change date + Skip live in identity card via `OccurrenceScheduleActionBar` |
| D-OSM-015 | Complete module has no “This date” header icon |
| D-OSM-016 | Open-state inline completion date row removed; DN-3 handled in phase 2 |

## Copy

- Schedule change button: **Change date** (`rescheduleActionLabel`), not “Reschedule”.

## Risks

See execute-plan `care-date-evolution-b20d` § Risks (R1–R6).
