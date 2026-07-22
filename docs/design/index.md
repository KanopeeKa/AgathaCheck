# Design guidance (agent map)

Lightweight by default. Go deeper only when the task needs it.

## Tiers

| Tier | When | What to load |
|------|------|----------------|
| **0 — Everyday** | Small UI fix, one widget, routine feature work | `.cursor/rules/design.mdc` + `accessibility.mdc` |
| **1 — UI check** | Review before merge, polish pass, “does this feel right?” | Skill `/ui-check` |
| **2 — Design deep** | New flow, auth/landing refresh, theme work, multi-screen consistency | Skill `/ui-design-deep` + `principles.md` |

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
