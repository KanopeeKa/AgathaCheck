---
title: Design principles (deep reference)
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-23
tags: [design,ui,ux]
---
# Design principles (deep reference)

Read when using `/ui-design-deep` or planning a UI refactor. Everyday work does **not** need this file.

## Personality

Calm, dependable, emotionally intelligent, low-stress. Users feel oriented and in control.

**Avoid:** bright pet-store palettes, cartoon motifs, novelty fonts, rainbow dashboards, cute copy in operational workflows, generic startup gradients, decorative blobs, center-aligned everything by default.

## Audience

One design system; subtle context via `AppExperience` (`/pc/*` Pet Care, `/o/*` Shelter), copy, and selective accent — not two brands. Shelter (teal) product copy rules: `copy-tone.md`.

The landing/auth surface is intentionally **role-neutral**. It introduces
AgathaTrack as a shared care-coordination desk; guardian, shelter, foster, and
organisation context is resolved after authentication rather than through a
pre-login chooser.

## Visual direction

- Warm neutral surfaces; hierarchy from spacing and typography more than decorative colour
- **Guardian** and **Shelter** each have a primary accent for CTAs in their experience context — never use colour alone for permission or severity
- **Coral** is decorative only — never a primary action, error, or warning colour
- Semantic colours stay functional and shared across modes
- **Landing / auth** uses the Operations Desk direction: warm paper, Pet Care plum primary, Shelter teal story surface, protective arch mark — see [`system.md`](./system.md) and [`tokens.md`](./tokens.md) for exact values (Replit-approved canonical)

**Colour values:** [`tokens.md`](./tokens.md) only. **Components and layout:** [`system.md`](./system.md). **Implementation:** `flutter_app/lib/core/theme/`

## Layout

- Left-align content-heavy and operational areas
- Center only for tight auth/hero moments
- Mobile-first: single column, reachable actions, no hover-only behavior
- Collapse complexity on small screens — do not shrink into illegibility

## Motion

Subtle and purposeful; respect `prefers-reduced-motion`. No decorative loops or gamified bounce in operational flows.

## Forms and operations

Clear persistent labels; specific actionable errors; confirmations proportional to risk. Scheduling, medication, assignments, and status updates favor clarity over decoration.

## Review output (deep tasks)

When reporting findings:

1. Problem · 2. Why it matters · 3. UX impact · 4. A11y impact · 5. System impact · 6. Proposed fix · 7. Reusable rule · 8. Implementation notes · 9. Acceptance checklist

Label each item as **requirement** (a11y/usability), **recommendation**, or **preference**.
