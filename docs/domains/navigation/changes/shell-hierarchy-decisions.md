---
title: Shell hierarchy decisions — brand once per navigation context
owner: Experience Program Team
audience: both
status: active
last_updated: 2026-09-03
tags: [navigation, guardian, shell, hierarchy]
---

# Shell hierarchy decisions (Guardian responsive chrome)

**Plan:** `guardian-shell-hierarchy-0b2d` · **Parent:** [guardian-adaptive-nav-7221](/.agents/plans/guardian-adaptive-nav-7221.md) (rail/sidebar shipped) · **Control issue:** #877

## Purpose

Refine Guardian shell **information hierarchy** across breakpoints so product identity, workspace scope, primary navigation, and page content do not compete. This is not an IA or rebrand change.

## Locked decisions

| ID | Decision | Status |
|----|----------|--------|
| **D-shell-1** | **One product identity per navigation context.** When persistent leading navigation is visible (≥600px Guardian), `AgathaTrack` appears only in that leading chrome — not duplicated in the main app bar on section roots. | locked |
| **D-shell-2** | **Section roots** (`/pc/home`, `/o/orgs`, `/account` per `DrawerMenuConfig.sectionRootPaths`) with leading nav visible: **omit** app bar title when it would repeat product or section identity already shown in leading nav. Dashboard home relies on active **Dashboard** nav state + body content for context. | locked |
| **D-shell-3** | **Contextual app bar titles retained** on non-root and deep routes (pet name, “All pets”, “Events”, etc.) — these carry information the sidebar cannot. | locked |
| **D-shell-4** | **Workspace toggle** (`ExperienceWorkspaceToggle`) labels remain **Pet Care** / **Shelter** — workspace scope, not product identity. **Actions** stays a primary nav destination (`/pc/events`). | locked |
| **D-shell-5** | **Mobile (&lt;600px):** compact plum app bar keeps centered `AppLogoTitle` + workspace toggle + bell — no persistent leading nav, so app bar owns brand. | locked |
| **D-shell-6** | **Tablet (600–839px):** `GuardianNavigationRail` header carries compact brand (logo-only or truncated wordmark within 120px rail) above workspace toggle; app bar does not repeat product title on section roots. | locked |
| **D-shell-7** | **Desktop (≥840px):** `GuardianNavigationSidebar` header order: brand → workspace toggle (section roots) → divider → primary nav → footer Account. App bar does not repeat product title on section roots. | locked |
| **D-shell-8** | **Notification bell** stays globally accessible; on medium+ prefer association with the **content column** rather than spanning above the branded sidebar column (Phase 4 polish). Behaviour unchanged. | locked |
| **D-shell-9** | **Workspace toggle visual weight** demoted below brand (lighter typography / subtler border) so scope reads below identity, not as a second page title. | locked |
| **D-shell-10** | **Out of scope:** dashboard body sections, pet cards, Care Tasks/Team, selector behaviour, notification behaviour, org `/o/orgs` parity (debt), Actions nav vs Events app bar label mismatch (debt). | locked |

## Breakpoint summary

| Width | Brand | Workspace scope | Primary nav | App bar title (section root) |
|-------|-------|-----------------|-------------|------------------------------|
| &lt;600px | App bar `AppLogoTitle` | App bar leading toggle | Bottom nav | Centered title (mobile) |
| 600–839px | Rail header (compact) | Rail leading toggle | Navigation rail | **Suppressed** on section roots |
| ≥840px | Sidebar header | Sidebar below brand | Sidebar list + Account footer | **Suppressed** on section roots |

## Deferred debt

| Topic | Tracking |
|-------|----------|
| Organisation `/o/orgs` brand duplication (shared shell) | Open debt issue when Guardian phases complete |
| Nav label **Actions** vs app bar **Events** on `/pc/events` | Open debt issue — naming only |

## References

- [navigation-decisions.md](../features/navigation-decisions.md) — D-v4-3..5
- [navigation-contract.md](/docs/e2e/navigation-contract.md) — Playwright expectations
- `ExperienceShellScaffold`, `GuardianNavigationSidebar`, `GuardianNavigationRail`
