---
title: Shelter dashboard v2 framing decisions
owner: Experience Program Team
audience: both
status: draft
last_updated: 2026-09-03
tags: [shelter, dashboard, navigation, framing]
---

# Shelter dashboard v2 framing decisions (draft)

**Plan:** `shelter-dashboard-v2-c4e8` · **Parent:** product review 2026-09-03

> **Status:** Draft for human review — not locked until `approve-autonomous shelter-dashboard-v2-c4e8`.

## Purpose

Evolve the Shelter workspace from a **light membership hub** into a **Care-shaped operations desk**: primary navigation (bottom / leading), cross-org **Shelter tasks** preview, **pinned shelter** in nav, and membership tiles with richer directory metadata — while keeping the **teal-only** palette (`organizationLight`, `organizationPrimary`).

## Supersedes

| Prior ID | Change |
|----------|--------|
| **D-desk-S1** | Revoked — dashboard includes **Shelter tasks** (incl. pending invites) + **My organisations**; rename hub → **Shelter dashboard** (`/o/orgs`). |
| **D-desk-S5** | Revoked — Shelter adopts primary nav (D-shelter-NAV-1). |
| **D-v4-2** (Shelter clause) | Revoked — Shelter has its own bottom/rail/sidebar destinations; workspace toggle remains for **Pet Care ↔ Shelter** on every screen (D-v5-WORKSPACE-4). |
| **D-v3-IA-2** | Amended — Discover is a **primary nav** destination, not a hub body row. |
| **D-v3-NAV-1** (dashboard chrome) | Amended — brand-once in leading nav per D-shell-1/2; no duplicate “Organisations dashboard” hero block. |
| **D-desk-S2** (tile geometry) | Owned by **`unified-pet-tile-c4e8`** — this plan consumes that tile, adds pin overlay only. |

## Locked decisions (pending approval)

| ID | Decision | Status |
|----|----------|--------|
| **D-desk-S7** | **Shelter tasks preview** on `/o/orgs`: cross-org actionable items (role-aware workflows, fostering session attention, **pending org invites**). Distinct from notification bell history (Administrative kind). Cap list length; calm empty state. | draft |
| **D-desk-S8** | **Teal-only Shelter chrome:** leading nav / bottom bar selected state uses `organizationPrimary`; surfaces use `organizationLight` / `surface`; task blocks use `organizationLight` (not Care `background` or plum). Semantic warning/danger unchanged. | draft |
| **D-shelter-NAV-1** | Shelter primary destinations: **Dashboard** (`/o/orgs`), optional **pinned org** (`/o/orgs/:id`), **Discover** (`/o/discover` or canonical discover route), **Account** (`/account`). Same breakpoints as D-v4-4 (compact &lt;600, rail 600–839, sidebar ≥840). **Persistent** on org deep routes (“heavier” shell). | draft |
| **D-shelter-NAV-2** | **One pinned org** per user, stored as **account preference** (cross-device). Pin control: icon top-right of membership tile cover. Nav slot hidden when unset. Pin target always org profile `/o/orgs/:id`. Replace-on-pin; clear on membership loss. | draft |
| **D-shelter-NAV-3** | **Five-slot nav geometry** matches Pet Care bar width; centre slot(s) render **inactive spacers** when pinned org unset (do not collapse bar). | draft |
| **D-shelter-TILE-1** | Hub membership card: **bio** blurb (ellipsis); **town + postcode** under name (postcode from `public_profile_metadata` when present). Visual ratios owned by `unified-pet-tile-c4e8`. | draft |
| **D-shelter-TASKS-1** | Tasks scope = **all org memberships**; v1 aggregates from existing client APIs (no dedicated tasks endpoint required for merge). | draft |

## Shelter dashboard body order (`/o/orgs`)

1. **My organisations** — grid of membership tiles (no page-level “Shelters Dashboard” header/subtitle).
2. **Shelter tasks** — eyebrow + preview rows (invites folded here).
3. No Discover row in body (nav only).

## Pin UX copy (EN)

| Context | Copy |
|---------|------|
| Unpinned tooltip | Pin to menu |
| Pinned tooltip | Pinned to menu — tap to unpin |
| Semantics (unpinned) | Pin {org name} to navigation |
| Semantics (pinned) | {org name} pinned to navigation |
| Nav destination label | Org short name (truncate); compact widths may use logo-only |
| First-visit hint (optional v1.1) | Pin your main shelter for quick access from the menu |

Placeholder illustration: product asset TBD (`flutter_app/assets/shelter/`).

## References

- [shelter-desk-framing-decisions.md](./shelter-desk-framing-decisions.md) — superseded items
- [navigation-decisions.md](/docs/domains/navigation/features/navigation-decisions.md)
- [desk-framing-decisions.md](/docs/domains/pet_profile/changes/desk-framing-decisions.md) — pattern reference
- [tokens.md](/docs/design/tokens.md)
- Plan: `.agents/plans/unified-pet-tile-c4e8.md` (tile look-and-feel)
