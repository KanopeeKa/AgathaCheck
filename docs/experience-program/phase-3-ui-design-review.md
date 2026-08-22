---
title: Phase 3 UI design review (`/ui-design-deep`)
owner: Experience Program Team
audience: both
status: active
last_updated: 2026-08-21
tags: [experience,guardian,organisation]
---
# Phase 3 UI design review (`/ui-design-deep`)

**Plan:** `experience-program-36bd` phase 3  
**Brief:** [`briefs/organisation-dashboard-brief.md`](briefs/organisation-dashboard-brief.md)  
**Spec:** [`phase-3-organisation-presentation.md`](phase-3-organisation-presentation.md)  
**Date:** 2026-07-26

## 1. Scope

| Surface | Route | Experience |
|---------|-------|--------------|
| Organisation home | `/o/orgs` | My Organisations + Discover Organisations |
| Org internal dashboard | `/o/orgs/:id` | Section-card hub (replaces long detail page) |
| Organisation Presentation | `/o/orgs/:id/presentation` | Public-facing identity (cover, logo, legal, contact) |
| Admin Contacts | `/o/orgs/:id/admin-contacts` | Internal directory + self-card |
| Legal & Documents | `/o/orgs/:id/legal-documents` | Read-only endDrawer / slide-over |
| Pets (enhanced) | `/o/orgs/:id/pets` | Tabs + filters |

Shared components: `DashboardSection`, `OrgCard`, `ExperienceShellScaffold`, `org_screen_theme.dart`.

## 2. Audits

### UX

- **Problem:** `organization_detail_screen.dart` mixes branding, people, pets, connections, and admin actions on one scroll — weak hierarchy and hard to permission-gate. **Requirement**
- **Problem:** Discover Organisations missing — users cannot browse shelters without membership. **Requirement**
- **Recommendation:** Reuse Phase 2 `DashboardSection` for My Organisations preview on `/o/orgs` if list grows; full list remains primary for now.
- **Recommendation:** Internal org dashboard uses same card grid rhythm as Guardian `/g/home` (section title → preview → end link) for cross-experience consistency.

### A11y

- **Requirement:** Discover tiles and section cards use `MergeSemantics` + descriptive labels (name, town, type) — extend `OrgCard` pattern.
- **Requirement:** Legal & Documents slide-over: focus trap, `l.close` on dismiss, download actions labeled.
- **Requirement:** Pet tab chips: selected state not color-only — pair with weight/border (FilterChip pattern from notification panel).
- **Recommendation:** Admin Contacts self-card pinned first — announce via heading order, not only visual position.

### Design

- **Requirement:** Organisation accent teal `#218B6C` via `ExperienceColors.organizationPrimary` / `org_screen_theme.dart` — no scattered greens.
- **Requirement:** Discover tiles show logo, name, town/admin area, description snippet only — never legal identifiers or admin phone numbers.
- **Recommendation:** Presentation hero uses cover + logo overlap (brief) — max height ~180dp mobile, avoid full-bleed that pushes actions below fold.
- **Preference:** Section cards on org dashboard use `Card` + `outlineVariant` border (match Guardian `DashboardSection`).

## 3. System-first proposals

| Order | Rule / pattern |
|-------|----------------|
| 1 | **Section-card hub** — one `OrgSectionCard` widget (icon, title, subtitle, chevron, `onTap`, optional permission gate wrapper) reused on org dashboard |
| 2 | **Discover list** — `OrgDiscoveryTile` composes `OrgCard` layout with public fields only; data from single `GET /organizations/discover` |
| 3 | **Permission-aware actions** — `OrgPermissionGate` wraps buttons; uses `hasPermission()` not inline `isOrgAdmin` |
| 4 | **Presentation screen** — extract from existing `organization_branding_section` + `organization_info_card` before adding new layout |
| 5 | **Pets tabs** — `TabBar` + shared filter chip row; tab state in screen, not global provider |

## 4. Phased rollout (this phase)

1. Foundation: schema + `hasPermission()` with real table (3.1–3.2)
2. Discover + org list section (3.3)
3. Dashboard decomposition + Presentation (3.4–3.5)
4. Admin Contacts + Legal slide-over (3.6–3.7)
5. Pet tabs/filters (3.8)
6. Audit wiring + BDD (3.9–3.10)

## 5. Acceptance checklist

- [ ] Theme tokens, not scattered colors
- [ ] Focus visible; touch targets ≥48dp
- [ ] l10n for all new strings (EN + FR)
- [ ] Empty, loading, error states on Discover and section cards
- [ ] Experience context `/o/*` respected (teal accent, org shell)
- [ ] `./scripts/pre-push-changed.sh` green
- [ ] BDD: discovery, permissions, pet filters scenarios mapped
- [ ] `organization_detail_screen.dart` removed (not shrunk)

## 6. Implementation notes

- Split `organization_detail_screen.dart` via `/split-flutter-screen` — target hub screen ≤200 lines, sections in dedicated files under `presentation/screens/org_dashboard/` and `presentation/widgets/org_dashboard/`.
- Admin Contacts: fork from `organization_people_section.dart` — do not duplicate foster-parent management (Phase 4 boundary).
- Legal slide-over: reuse `NotificationPanel` endDrawer width pattern (~88% viewport).
