# Design principles (deep reference)

Read when using `/ui-design-deep` or planning a UI refactor. Everyday work does **not** need this file.

## Personality

Calm, dependable, emotionally intelligent, low-stress. Users feel oriented and in control.

**Avoid:** bright pet-store palettes, cartoon motifs, novelty fonts, rainbow dashboards, cute copy in operational workflows, generic startup gradients, decorative blobs, center-aligned everything by default.

## Audience

One design system; subtle context via `AppExperience` (`/g/*` guardian, `/o/*` organisation), copy, and selective accent — not two brands. Org custom branding must not break text contrast or error/focus semantics.

## Visual direction (target)

- Warm neutral surfaces; hierarchy from spacing and typography more than decorative color
- Operational accent: muted sage / forest green (calm, trust, care)
- Secondary warmth: muted coral/peach sparingly for guardian/foster-facing moments
- Semantic colors (success, warning, danger) stay functional and accessible

**Current codebase:** theme is still purple-seed Material 3 (`app_theme.dart`). Treat palette above as migration target, not assumed present.

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
