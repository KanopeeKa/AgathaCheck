# Design principles (deep reference)

Read when using `/ui-design-deep` or planning a UI refactor. Everyday work does **not** need this file.

## Personality

Calm, dependable, emotionally intelligent, low-stress. Users feel oriented and in control.

**Avoid:** bright pet-store palettes, cartoon motifs, novelty fonts, rainbow dashboards, cute copy in operational workflows, generic startup gradients, decorative blobs, center-aligned everything by default.

## Audience

One design system; subtle context via `AppExperience` (`/g/*` guardian, `/o/*` organisation), copy, and selective accent — not two brands. Org branding rules: `copy-tone.md`.

The landing/auth surface is intentionally **role-neutral**. It introduces
AgathaTrack as a shared care-coordination desk; guardian, shelter, foster, and
organisation context is resolved after authentication rather than through a
pre-login chooser.

## Visual direction

- Warm neutral surfaces; hierarchy from spacing and typography more than decorative color
- **Guardian primary:** plum `#755B68` — full primary on `/g/*` CTAs
- **Organisation primary:** teal `#218B6C` — full primary on `/o/*` CTAs
- **Warm accent:** coral `#D6A08F` — restrained; never primary CTA
- **Success:** `#2B7A2E` (S2) — small signals, not large fills
- Semantic colors stay functional and shared across modes
- **Approved landing direction:** deep olive story panel, warm paper auth panel,
  muted gold mark/accent, and the protective shelter arch logo. See
  `tokens.md` for the landing reference values; this is pending production
  integration and does not silently replace the app-wide palette.

Tokens: `docs/design/tokens.md` · Implementation: `flutter_app/lib/core/theme/`

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
