---
title: Dashboard desk framing decisions — shell surfaces and section chrome
owner: Experience Program Team
audience: both
status: active
last_updated: 2026-09-03
tags: [guardian, dashboard, shell, framing]
---

# Dashboard desk framing decisions (Guardian `/pc/home`)

**Plan:** `guardian-desk-framing-6e46` · **Parent:** [guardian-shell-hierarchy-0b2d](/.agents/plans/guardian-shell-hierarchy-0b2d.md) (brand-once shipped) · **Control issue:** #928

## Purpose

Refine visual hierarchy between app shell navigation, main workspace canvas, and dashboard section previews on medium+ viewports — without redesigning pet/care/care-team/fostering row components.

## Locked decisions

| ID | Decision | Status |
|----|----------|--------|
| **D-desk-1** | **Navigation surface vs workspace canvas.** Persistent leading nav (rail/sidebar) uses semantic token `surface`. Main content column uses `background`. No vertical dividers, shadows, or card-wrapped sidebar. | locked |
| **D-desk-2** | **Mobile unchanged.** Compact plum app bar + bottom nav; no desktop sidebar framing on &lt;600px. | locked |
| **D-desk-3** | **Section chrome row.** Dashboard preview sections use one header row: eyebrow title (left) + optional “All …” text action (right) when a real full-screen destination exists. Section content sits below. | locked |
| **D-desk-4** | **No phantom “All …” links.** Show trailing section navigation only when overflow or non-empty list warrants a destination (same gating as today). | locked |
| **D-desk-5** | **Open canvas default.** Home preview sections do not wrap content in tinted `GuardianDeskSectionCard` shells. Local cards/rows provide grouping. Fostering org tint may remain as the cross-experience exception. | locked |
| **D-desk-6** | **Pets hero rail.** Pets preview may omit a PETS eyebrow when the horizontal pet rail is the visual anchor; “All pets” uses the same header-row chrome when shown. | locked |
| **D-desk-7** | **Dashboard max width.** Canonical content grid max width **1120px** on `/pc/home`, centered with responsive horizontal padding (16 / 24 / 32 by breakpoint). | locked |
| **D-desk-8** | **Sidebar active state.** Selected nav tile uses one primary channel (colour + optional slim left bar). Avoid oversized fill backgrounds that read as content cards. | locked |
| **D-desk-9** | **Out of scope:** redesign of `CareEventRow`, `CareTeamCard`, pet cards, fostering rows; shell-wide max width on every guardian route (hub routes optional follow-up); create actions in section headers (debt). | locked |

## Supersedes

| Prior | Change |
|-------|--------|
| `guardian-dashboard-brief.md` structural pattern | “End link at bottom” → **header-row** “All …” for dashboard previews (D-desk-3). Create actions remain on full screens or empty states unless a separate debt issue opens header create actions. |

## Breakpoint summary

| Width | Nav surface | Canvas | Section chrome |
|-------|-------------|--------|----------------|
| &lt;600px | Plum app bar + bottom nav | `background` full width | Header row; 16px padding |
| 600–839px | Rail `surface` | Column `background` | Header row; 24px padding |
| ≥840px | Sidebar `surface` | Column `background`, max 1120px centered | Header row; 24–32px padding |

## References

- [guardian-dashboard-brief.md](../features/guardian-dashboard-brief.md)
- [tokens.md](/docs/design/tokens.md) — dashboard section surfaces
- `ExperienceShellScaffold`, `GuardianOperationsDeskLayout`, `GuardianDashboardSectionHeader`
