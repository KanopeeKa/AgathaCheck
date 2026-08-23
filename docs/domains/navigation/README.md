---
title: Navigation domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-23
tags: [navigation, ux]
---

# Navigation

Shell navigation, routing UX, and experience switching (`/g/*`, `/o/*`).

| Folder | Contents |
|--------|----------|
| `features/` | Canonical navigation requirements (drawer, bell, section switcher, locked decisions) |
| `changes/` | Delivery plans and phased rollouts (Phase 0, 1, R) |

## Read first

| Doc | Purpose |
|-----|---------|
| [navigation-decisions.md](features/navigation-decisions.md) | Locked shell decisions D1–D6, D27 |
| [navigation-brief.md](features/navigation-brief.md) | Locked master brief (section switcher model) |
| [program-contract.md](/docs/domains/cross-domain/changes/program-contract.md) | Cross-cutting vocabulary and gates |
| [roadmap-delivery-plan.md](/docs/domains/cross-domain/changes/roadmap-delivery-plan.md) | Phase order R → 0 → 1 → 2–5 |

## Decision index (split from experience-program decisions log)

| Domain | File | IDs |
|--------|------|-----|
| Navigation | [navigation-decisions.md](features/navigation-decisions.md) | D1–D6, D27 |
| Notifications | [notification-decisions.md](/docs/domains/notifications/features/notification-decisions.md) | D7–D11 |
| Pet profile | [pet-profile-decisions.md](/docs/domains/pet_profile/features/pet-profile-decisions.md) | D17–D24, D34–D37 |
| Shelter | [shelter-decisions.md](/docs/domains/shelter/features/shelter-decisions.md) | D12–D16, D20–D31, D-v2-*, D-v3-*, D-v4-* |
| Cross-domain delivery | [delivery-decisions.md](/docs/domains/cross-domain/changes/delivery-decisions.md) | D32–D33 |

## Delivery plans

| Plan | Summary | Source |
|------|---------|--------|
| Phase R — Reconciliation | Close nav-v2 before new work | [phase-r-reconciliation.md](changes/phase-r-reconciliation.md) |
| Phase 0 — Foundation | Shared primitives, no UI change | [phase-0-foundation.md](changes/phase-0-foundation.md) |
| Phase 0 — Settings audit | Settings row destination map | [phase-0-settings-audit.md](changes/phase-0-settings-audit.md) |
| Phase 1 — Navigation | Drawer, header, bell, Account | [phase-1-navigation.md](changes/phase-1-navigation.md) |

Related: [/docs/e2e/navigation-contract.md](/docs/e2e/navigation-contract.md) (E2E test contract).

Supersedes: [/docs/archived/navigation-v2.md](/docs/archived/navigation-v2.md)
