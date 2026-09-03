---
title: Shelter desk framing decisions
owner: Experience Program Team
audience: both
status: active
last_updated: 2026-09-03
tags: [shelter, dashboard, shell, framing]
---

# Shelter desk framing decisions

**Plan:** `shelter-desk-parity-dd8e` · **Parent:** second-pass ui-design-deep review (2026-09-03)

## Purpose

Apply Care **operations-desk patterns** (section chrome, tile geometry, touch targets) to the Shelter workspace without copying Care navigation IA or the Pet Care plum palette.

## Locked decisions

| ID | Decision | Status |
|----|----------|--------|
| **D-desk-S1** | Shelter hub (`/o/orgs`) stays **membership + pending invites + discover entry** only. No workspace-level operational previews (need-attention queues, session feeds). | locked |
| **D-desk-S2** | Shelter visual parity uses **shared section chrome + pet-grid tile geometry** on the **teal canvas** (`organizationLight` `#EAF5F5`, `organizationPrimary` `#1D7C84`). Do not adopt Care `background` or plum primary for org chrome. | locked |
| **D-desk-S3** | Optional **summary counts on profile nav rows** only (not section previews). Pending-work badge counts remain DEF-NOTIF-COUNTS. | locked |
| **D-desk-S4** | `ExperienceWorkspaceToggle` is required on **all** org chrome including `OrgShellScaffold` (implements D-v5-WORKSPACE-4 for deep routes). | locked |
| **D-desk-S5** | Shelter does **not** get Care-style bottom/rail primary nav unless a future decision supersedes D-v4-2. | locked |

## Palette (Shelter tokens)

| Role | Token | Hex |
|------|-------|-----|
| Org canvas | `organizationLight` | `#EAF5F5` |
| Org primary / compact chrome | `organizationPrimary` | `#1D7C84` |
| Cards on canvas | `surface` | `#FFFDFC` |

## Section chrome (hub)

Mirror Care **D-desk-3** header-row pattern on the teal canvas:

- Eyebrow title (`labelLarge`, `organizationPrimary` or `organizationActive` emphasis)
- Supporting subtitle in `onSurfaceVariant`
- No filled `primaryContainer` hero wrappers around hub sections

## Hub tiles (D-v3-TILE-1)

My Organisations uses **pet-grid geometry** (2/3 media, 1/3 meta). No-hero fallback = solid `organizationPrimary`.

## References

- [navigation-decisions.md](/docs/domains/navigation/features/navigation-decisions.md) — D-v4-2, D-v5-WORKSPACE-4
- [desk-framing-decisions.md](/docs/domains/pet_profile/changes/desk-framing-decisions.md) — Care desk (plum canvas; pattern reference only)
- [organisation-ux-v3-delivery-plan.md](./organisation-ux-v3-delivery-plan.md) — D-v3-NAV-1, D-v3-TILE-1
