# Phase 5 UI design review (`/ui-design-deep`)

**Plan:** `experience-program-36bd` phase 5  
**Spec:** [`phase-5-organisation-customisations.md`](phase-5-organisation-customisations.md)  
**Date:** 2026-07-26

## 1. Scope

| Surface | Route | Experience |
|---------|-------|------------|
| Org edit | `/o/orgs/:id/edit` | Super Admin only: link to customisations |
| Customisations hub | `/o/orgs/:id/customisations` | Templates + Roles & Permissions cards |
| Document templates | `/o/orgs/:id/customisations/templates` | Reuses G1 API — list session/adoption templates |
| Roles & Permissions | `/o/orgs/:id/customisations/roles` | Bundle presets, overrides, audit log |

**Guardrail (D25):** No customisations entry from dashboard, presentation, or discover — edit screen only.

## 2. Audits

### UX

- **Requirement:** Single hub avoids scattering Super Admin config across dashboard cards.
- **Requirement:** Member picker + bundle preset before individual overrides — reduces permission confusion.
- **Recommendation:** Audit log as bottom section on roles screen (scroll) not a third top-level card — keeps hub to two tiles.

### A11y

- **Requirement:** Section cards reuse `OrgSectionCard` semantics (≥48dp touch, chevron + label).
- **Requirement:** Permission toggles use `SwitchListTile` with permission key in semantics label.
- **Recommendation:** Audit rows: `ListTile` with `subtitle` for timestamp; action as title.

### Design

- **Requirement:** Teal org accent via `org_screen_theme.dart` — no new palette.
- **Requirement:** Super Admin gate uses `manage_permissions` via `hasPermission()`, not `isOrgSuperUser` alone.

## 3. System-first proposals

| Order | Pattern |
|-------|---------|
| 1 | Reuse `OrgSectionCard` on customisations hub |
| 2 | `OrgPermissionGate` wrapper on edit-screen entry link |
| 3 | New `organization_permissions_remote.dart` + providers — wire `orgPermissionOverrides()` |
| 4 | Template list read-only first slice; toggle `is_public` if API exists |

## 4. Acceptance checklist

- [ ] Theme tokens, not scattered colors
- [ ] Focus visible; touch ≥48dp
- [ ] l10n EN + FR for new strings
- [ ] Empty/loading/error on templates and audit log
- [ ] Entry only from org edit; hidden from non–Super Admin
- [ ] `./scripts/pre-push-changed.sh` green
- [ ] BDD `organisation_customisations.feature` mapped
