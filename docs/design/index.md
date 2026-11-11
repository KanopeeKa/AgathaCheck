---
title: Design guidance (agent map)
owner: Documentation Team
audience: both
status: active
last_updated: 2026-11-10
tags: [design,ui,ux]
---
# Design guidance (agent map)

Lightweight by default. Go deeper only when the task needs it.

## Tiers

| Tier | When | What to load |
|------|------|----------------|
| **0 — Everyday** | Small UI fix, one widget, routine feature work | `.cursor/rules/design.mdc` + `accessibility.mdc` |
| **1 — UI check** | Review before merge, polish pass, “does this feel right?” | Router → `.cursor/agent-kernel/protocols/accessibility.md` §Quick pass |
| **2 — Design deep** | New flow, auth/landing refresh, theme work, multi-screen consistency | Skill `/ui-design-deep` + `true-north.md` + `principles.md` + `system.md` |
## Theme project

**Canonical system:** [`system.md`](./system.md) (Operations Desk / Replit direction).  
**Token tables:** [`tokens.md`](./tokens.md) — only file for hex colour values.  
**Execution plans:** [`plans/ui-rework-plan.md`](./plans/ui-rework-plan.md), [`plans/agathatrack-redesign-blueprint.md`](./plans/agathatrack-redesign-blueprint.md).

## Reference implementations

Copy patterns from these — do not invent parallel styles:

| Pattern | Path |
|---------|------|
| Experience shell + nav | `features/experience/presentation/widgets/experience_shell_scaffold.dart` |
| Accessible tappable card | `core/widgets/cards/` (reuse established list patterns) |
| Pet list + sections | `features/pet_profile/presentation/screens/pet_list_screen.dart` |
| Auth / landing layout | `features/auth/presentation/screens/landing_screen.dart` |
| Theme (current) | `flutter_app/lib/core/theme/app_theme.dart` |

## Approved landing/auth direction

The reviewed landing direction is the **AgathaTrack Care Desk** treatment:

- Warm-paper auth surface, Guardian-plum primary action, and the approved protective arch mark on the landing story surface.
- Authentication is role-neutral on the landing page; Pet Care is the only active workspace after sign-in.
- Preserve the existing email/password, password visibility, forgot-password, validation, localization, accessibility, and native web password-manager behavior when this direction is integrated.

The approved static preview is `shape:guardian-care-landing-static` on the
canvas. Its companion source files are the plum/teal landing image and logo
board in `attached_assets/`. The older olive/gold `GuardianDesk.tsx` mockup is
historical only. The expanded palette, typography, layout, and interaction
roles live in [`system.md`](./system.md) and [`tokens.md`](./tokens.md).

## Phased UI refactor (only when explicitly requested)

1. **Tokens** — `app_theme.dart` only; no screen churn
2. **Shared patterns** — buttons, inputs, empty/loading/error in `core/` or reused widgets
3. **High-traffic screens** — landing, home, pet detail
4. **Long tail** — edge flows and secondary surfaces

One verifiable outcome per PR (atomic PR policy).

## Code anchors

| Topic | Path |
|-------|------|
| Theme | `flutter_app/lib/core/theme/app_theme.dart` |
| Experiences | `flutter_app/lib/features/experience/`, `docs/archived/experience-split-plan.md` |
| Auth / landing | `flutter_app/lib/features/auth/presentation/` |
| A11y + E2E | `.cursor/rules/accessibility.mdc`, `e2e/playwright/support/axe.ts` |

## Product direction and voice

| Doc | Owns |
|-----|------|
| [`true-north.md`](./true-north.md) | Why — values and active product direction (Pet Care centre of gravity) |
| [`copy-tone.md`](./copy-tone.md) | How the product sounds — register, patterns, examples |
| [`terminology.md`](./terminology.md) | Pet parent, care roles, legal terms, l10n rules |
| [`principles.md`](./principles.md) | Visual personality, layout, motion (deep reference) |

**Bridge sentence:** AgathaTrack coordinates care calmly; it should feel like a trusted companion in how it speaks — not like a taskmaster or engagement app.

Shelter and Fostering code was removed in 2026-11; engineering record under [`frozen-domains`](../engineering/frozen-domains/).
