---
title: Care date screen v4 (four blocks)
domain: pet_care
status: proposed
status_since: 2026-10-14
folds_into: docs/domains/pet_care/features/care-item-evolution.md
last_updated: 2026-10-14
---

# Care date blocks v4 — proposal

Folds into `care-item-evolution.md` § Care date screen when plan `care-date-blocks-v4-e8f1` completes.

## Wireframe (Block 1)

```
┌─────────────────────────────────────────────────────────────┐
│ [Pet avatar]   Care name (link)                    [Family │
│  Pet name      Dose line                            icon]  │
│                Strength / Form (med families, if set)     │
│                Category label (under icon)                │
└─────────────────────────────────────────────────────────────┘
```

- Left: pet avatar (tap → pet profile). Pet name under avatar.
- Centre: linked care name; dose line; optional strength + form.
- Right: care family icon + category label.
- No recurring icon. No “View care details” link.

## Blocks 2–4

See execute-plan `care-date-blocks-v4-e8f1` acceptance criteria.

## Completion (Option a)

- `completed_on` is **date only** (no migration this programme).
- Open completion **time** control shows **scheduled time** read-only (not stored as completion time).
- Default completion date: `min(due_date, as_of.date)` (pet home day).
