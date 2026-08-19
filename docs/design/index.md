# Design guidance (agent map)

Lightweight by default. Go deeper only when the task needs it.

## Tiers

| Tier | When | What to load |
|------|------|----------------|
| **0 — Everyday** | Small UI fix, one widget, routine feature work | `.cursor/rules/design.mdc` + `accessibility.mdc` |
| **1 — UI check** | Review before merge, polish pass, “does this feel right?” | Skill `/ui-check` |
| **2 — Design deep** | New flow, auth/landing refresh, theme work, multi-screen consistency | Skill `/ui-design-deep` + `principles.md` |

## Theme project

**Execution plan:** `ui-rework-plan.md` (phases 0–7).  
**Navigation v2:** `navigation-v2.md` (execute-plan `ui-navigation-v2-14ee`).  
**Deliverable in Phase 0:** `tokens.md` — live at `docs/design/tokens.md`.  
**Changing the color scheme (re-skin)?** Start at `skin-change-guide.md` —
the single file to edit plus every companion file (logos, web manifest,
PDF reports, emails) that needs updating alongside it.

## Reference implementations

Copy patterns from these — do not invent parallel styles:

| Pattern | Path |
|---------|------|
| Experience shell + nav | `features/experience/presentation/widgets/experience_shell_scaffold.dart` |
| Accessible tappable card | `features/organization/presentation/widgets/org_card.dart` |
| Pet list + sections | `features/pet_profile/presentation/screens/pet_list_screen.dart` |
| Auth / landing layout | `features/auth/presentation/screens/landing_screen.dart` |
| Theme (current) | `flutter_app/lib/core/theme/app_theme.dart` |

## Approved landing/auth direction

The reviewed landing direction is the **AgathaTrack Operations Desk** treatment:

- Calm deep olive story panel, warm-paper auth surface, muted gold accent, and the approved protective shelter arch mark.
- A short shelter/foster-team message is supporting context, not an audience gate.
- Authentication is role-neutral: the landing page offers sign-in/create-account only. Guardian, shelter, organisation, and other care contexts are resolved inside the authenticated app.
- Preserve the existing email/password, password visibility, forgot-password, validation, localization, accessibility, and native web password-manager behavior when this direction is integrated.

The live reference is `artifacts/mockup-sandbox-live/src/components/mockups/landing-auth/GuardianDesk.tsx`; the approved static preview is `shape:guardian-care-landing-static` on the canvas. The expanded palette, typography, layout, and interaction roles live in `tokens.md`. This is a landing-direction decision, not a replacement of the current global Flutter tokens until production integration is explicitly implemented.

## Phased UI refactor (only when explicitly requested)

1. **Tokens** — `app_theme.dart` only; no screen churn
2. **Shared patterns** — buttons, inputs, empty/loading/error in `core/` or reused widgets
3. **High-traffic screens** — landing, home, pet detail
4. **Long tail** — org dashboards, edge flows

One verifiable outcome per PR (atomic PR policy).

## Code anchors

| Topic | Path |
|-------|------|
| Theme | `flutter_app/lib/core/theme/app_theme.dart` |
| Experiences | `flutter_app/lib/features/experience/`, `docs/experience-split-plan.md` |
| Auth / landing | `flutter_app/lib/features/auth/presentation/` |
| A11y + E2E | `.cursor/rules/accessibility.mdc`, `e2e/playwright/support/axe.ts` |

## Product north star (one line)

Dependable care coordination — calm, trustworthy, humane, efficient for all-day use.
