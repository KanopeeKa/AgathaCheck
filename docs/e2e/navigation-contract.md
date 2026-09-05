---
title: E2E navigation contract
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-04
tags: [documentation]
---
# E2E navigation contract

Playwright page-object **action methods** (open, navigate, goBack) must not return until:

1. The **expected route pattern** matches (`waitForFlutterRoutePattern`), and
2. The page-specific **ready locator** is visible (`expectLoaded` or equivalent).

Route wait alone is insufficient: Flutter web can update the hash before the semantics tree and widgets are interactive.

## Fallback pattern

When shell detection or drawer clicks fail, call `navigateWithShellFallback()` in `e2e/playwright/support/flutter.ts`. It hash-navigates directly, waits for the route, runs `readyFn`, and logs `E2E_NAV_FALLBACK` with a fixed JSON payload for CI grep.

Use fallback **only** after the normal path fails. Healthy localhost runs should emit **zero** fallback warnings.

## Flutter 3.44 semantics fallbacks (PR #497+)

Flutter web 3.44 changed how some widgets surface in the accessibility tree:

| Widget pattern | Prefer | Fallback roles |
|----------------|--------|----------------|
| MergeSemantics labels (pet cards, profile rows) | `button` | `checkbox`, `tab`, `group` — use `semanticsByName()` |
| Dashboard sections (`DueEventsSection`) | `group` | `region`, `tabpanel` — use `dashboardSectionGroup()` |
| Pet Care illustrated empty states (`GuardianIllustratedEmptyState` until renamed) | `group` (merged title+body label) | `button` for action — use `semanticsByName()`, not `getByText()` |
| Org pets filter tabs (`All` / `Tous`) | `tab` | `button`, `checkbox` |
| Profile field values on My Details | `button` | `checkbox` |
| Share sheet **Copy link** | `button` | `checkbox` |

When adding new page-object locators, chain `.or()` fallbacks in this order rather than asserting a single role.

## API seed ordering (live UAT)

When seeding via `playwright/support/api.ts` and asserting on the **home pet list**, create data **before** `loginAs` using `testUser.accessToken`. Post-login API creates leave a stale empty list on live UAT (passes on fast localhost).

```ts
const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
const petList = await loginAs(page, testUser);
await petList.expectPetVisible(pet.name);
```

For **due events on home** after API seed, call `refreshByRemount()` — the section does not hot-reload. Details: [`docs/e2e/uat-live-operations-runbook.md`](../docs/e2e/uat-live-operations-runbook.md).

## Due events on home (PR C)

After API seeding, the Pet Care home `DueEventsSection` does not refresh until the screen remounts. Use `PetListPage.refreshByRemount()` before asserting due entries on `/pc/home`. The events-screen assertion in #216 was a temporary workaround.

## Pet Care workspace naming (D38)

Routes use `/pc/*`. Wire value `pet_care` replaces legacy `guardian` for experience scope. Some Flutter/E2E identifiers still use `guardian_*` prefixes until a follow-up rename lands.

| Surface | EN | FR |
|---------|----|----|
| Workspace (toggle / drawer) | Pet Care | Suivi |
| Dashboard pet-rail section | My Pets | Mes animaux |
| Due-items dashboard eyebrow | CARE ACTIONS | SOINS |
| Link to full due list | All Actions | Tous les soins |
| Bottom nav tab | Actions | Soins |

Full map: [pet_care domain rename plan](/docs/domains/pet_care/changes/domain-rename-plan.md).

## Pet Care compact bottom nav (D-v4-1)

Viewport **&lt;600px** exposes the five-tab bottom bar (`Key('guardian_bottom_navigation')` until renamed) on all Pet Care workspace routes.

| Tab label (EN) | Tab label (FR) | Route | Ready locator |
|--------------|----------------|-------|---------------|
| Dashboard | Tableau de bord | `/pc/home` | Pet Care home care region or **My Pets** section |
| Pets | Animaux | `/pc/pets` | `All Pets` / `Tous les animaux` |
| Actions | Soins | `/pc/events` | `HealthDashboardPage.expectLoaded()` |
| Fostering | Accueil | `/pc/fostering` | `Fostering Sessions` / `Sessions d'accueil` |
| Account | Compte | `/account` | Account section rows |

Page object: `GuardianDashboardPage.openBottomNavTab(label)`, `openFosteringViaBottomNav()`.

Selector order for tabs: `getByRole('button', { name })` → `getByRole('tab', { name })` (Flutter 3.44 semantics).

Nested routes highlight the closest tab (e.g. `/pet/pet-1` → Pets; `/pet/pet-1/events` → Actions).

## Pet Care leading navigation rail (D-v4-4, medium)

Viewport **600–839px** exposes `GuardianNavigationRail` (`Key('guardian_navigation_rail')`) with the same five destinations as compact bottom nav.

| Destination (EN) | Route | Notes |
|------------------|-------|-------|
| Dashboard | `/pc/home` | Same ready locators as bottom nav |
| Pets | `/pc/pets` | |
| Actions | `/pc/events` | |
| Fostering | `/pc/fostering` | |
| Account | `/account` | Fifth rail destination |

**Shell hierarchy (D-shell-6):** rail header carries compact `AgathaTrack` brand (logo) above workspace toggle on section roots. App bar does **not** repeat product title on section roots (`/pc/home`, `/account`).

Page object: `GuardianDashboardPage.openLeadingNavDestination(label)` (viewport-aware: rail vs sidebar vs bottom nav).

The hamburger drawer is **not** available at these widths.

## Pet Care expanded sidebar (D-v4-4, expanded)

Viewport **≥840px** exposes `GuardianNavigationSidebar` (`Key('guardian_navigation_sidebar')`) at ~240px width.

- Header: brand + workspace toggle (`experience_workspace_toggle`)
- Body: Dashboard, Pets, Actions, Fostering (with optional trailing badge on Actions — deferred)
- Footer: Account (pinned, separated by divider)

**Shell hierarchy (D-shell-1):** app bar does **not** repeat `AgathaTrack` on Pet Care section roots; brand lives in sidebar header only.

Page object: same `openLeadingNavDestination(label)` helper; Account via footer row.

**E2E (D-shell-1/6):** `guardian.navigation.spec.ts` asserts one `AgathaTrack` text at 390px (app bar) and 1024px (sidebar only), logo-only rail brand at 720px (`guardian_navigation_rail_brand`), and notification bell outside leading nav via `GuardianDashboardPage.expect*ShellHierarchy()`.

The hamburger drawer is **not** available at these widths.

## Workspace toggle (D-v4-3, D-v5-WORKSPACE-4)

`ExperienceWorkspaceToggle` (`Key('experience_workspace_toggle')`) is available on **every authenticated experience screen** (not only section roots).

| Width | Placement |
|-------|-----------|
| **&lt;600px** | App bar: toggle on all routes; back + toggle on non-root |
| **600–839px** | Rail header: toggle always; content chrome: back on non-root |
| **≥840px** | Sidebar header: toggle always; content chrome: back on non-root |

Section roots (`/pc/home`, `/o/orgs`, `/account`) show toggle without back arrow.

| Action | Locator | Post-action ready |
|--------|---------|-------------------|
| Assert visible | `workspaceToggleLocator()` or `GuardianDashboardPage.expectWorkspaceToggleVisible()` | Toggle pill or `Choose your workspace` semantics |
| Open menu | `GuardianDashboardPage.openWorkspaceMenu()` | Menu items **Pet Care** / **Suivi** and **Shelter** / **Refuges** |
| Switch to Shelter | `selectWorkspaceMenuItem(/^Shelter$|^Refuge$/i)` | `/o/orgs` + `OrganizationListPage.expectLoaded()` |
| Switch to Pet Care | `selectWorkspaceMenuItem(/^Pet Care$|^Suivi$/i)` | `/pc/home` + dashboard care region |
| My Pets section (not workspace) | `dashboardSectionGroup(page, 'myPets')` or `/My Pets\|Mes animaux/i` | Pet-rail preview on home — unchanged label |

Shelter menu item is **always** visible (D-v5-WORKSPACE-1). Non-members land on `/o/orgs` empty state.

### Shelter hub chrome (D-desk-S7, D-shelter-NAV-1)

| Surface | Route | Ready locator / assertion |
|---------|-------|---------------------------|
| Dashboard body | `/o/orgs` | **My Organisations** eyebrow (`myOrganizations` l10n) + `Key('shelter_tasks_preview')` |
| Membership grid | `/o/orgs` (has memberships) | `Key('org_membership_grid')`; cards `flt-semantics-identifier="org_membership_<id>"` |
| Membership empty | `/o/orgs` (no memberships) | `orgNoOrganizations` copy (no grid key) |
| Hub compact app bar | `/o/orgs` (width &lt;600px) | Teal `organizationPrimary` bar; `Key('experience_workspace_toggle')` without back |
| Org deep shell | `/o/orgs/:orgId/**` | `Key('experience_back_button')` on non-root routes; Shelter primary nav **persistent** (D-shelter-NAV-1) |
| Workspace switch | Any authenticated shell | `Key('experience_workspace_toggle')` on every screen (D-v5-WORKSPACE-4) |

Discover is **nav-only** (no `org_discover_nav_row` in dashboard body). Pending invites fold into **Shelter tasks** — not a separate hub section.

## Shelter compact bottom nav (D-shelter-NAV-1)

Viewport **&lt;600px** exposes the five-slot bottom bar (`Key('shelter_bottom_navigation')`) on all Shelter workspace routes (except `/o/onboarding`).

| Tab label (EN) | Tab label (FR) | Route | Semantics identifier |
|----------------|----------------|-------|----------------------|
| Dashboard | Tableau de bord | `/o/orgs` | `shelter_nav_dashboard` |
| *(pinned org)* | *(org short name)* | `/o/orgs/:id` | `shelter_nav_pinned_org` — slot hidden when unset |
| *(spacer)* | — | — | inactive centre slot when unpinned (D-shelter-NAV-3) |
| Discover Organisations | Découvrir des organisations | `/o/orgs/discover` | `shelter_nav_discover` |
| Account | Compte | `/account` | `shelter_nav_account` |

Selector order for tabs: `getByRole('button', { name })` → `getByRole('tab', { name })` → `flt-semantics-identifier` (Flutter 3.44 semantics).

Nested org routes highlight **Dashboard** when unpinned, or **pinned org** when the path matches the pin (e.g. `/o/orgs/org-1/pets` → pinned slot).

## Shelter leading navigation rail (D-shelter-NAV-1, medium)

Viewport **600–839px** exposes `ShelterNavigationRail` (`Key('shelter_navigation_rail')`, `flt-semantics-identifier="shelter_navigation_rail"`) with the same destinations as compact bottom nav (no spacer slots).

| Destination (EN) | Route | Notes |
|------------------|-------|-------|
| Dashboard | `/o/orgs` | Same ready locators as bottom nav |
| *(pinned org)* | `/o/orgs/:id` | Hidden when unset |
| Discover Organisations | `/o/orgs/discover` | |
| Account | `/account` | Fourth rail destination when unpinned |

**Shell hierarchy:** rail header carries compact `AgathaTrack` brand (`shelter_navigation_rail_brand`) above workspace toggle on section roots.

The hamburger drawer is **not** available at these widths.

## Shelter expanded sidebar (D-shelter-NAV-1, expanded)

Viewport **≥840px** exposes `ShelterNavigationSidebar` (`Key('shelter_navigation_sidebar')`, `flt-semantics-identifier="shelter_navigation_sidebar"`) at ~240px width.

- Header: brand + workspace toggle (`experience_workspace_toggle`)
- Body: Dashboard, optional pinned org, Discover
- Footer: Account (pinned, separated by divider)

Org deep routes keep sidebar/rail/bottom nav visible. The hamburger drawer is **not** available at these widths.

## Shelter tasks preview (D-shelter-TASKS-1)

Cross-org actionable items on `/o/orgs` inside `Key('shelter_tasks_preview')`.

| Locator | When |
|---------|------|
| `Key('shelter_tasks_preview')` | Section root — always on dashboard |
| `Key('shelter_tasks_card')` | Loaded task data |
| `Key('shelter_tasks_empty')` | Calm empty state (`guardianEmptyCareClearTitle` / `homeNoDueEvents`) |
| `Key('shelter_task_row_<id>')` | Individual task row |
| `Key('shelter_task_accept_<inviteId>')` | Pending invite accept |
| `Key('shelter_task_decline_<inviteId>')` | Pending invite decline |

Eyebrow label uses `shelterTasksEyebrowLabel` l10n. Invite rows use invite copy — not a separate **Pending Invitations** hub header.

## Shelter membership pin (D-shelter-NAV-2)

Pin control on membership tile cover (`OrgMembershipTile`).

| Locator | Purpose |
|---------|---------|
| `flt-semantics-identifier="shelter_membership_pin_<orgId>"` | Pin/unpin button (48dp touch target) |
| `Key('org_membership_tile_<orgId>')` | Tile widget key (cover + meta) |

Semantics labels (EN): `Pin {org name} to navigation` (unpinned); `{org name} pinned to navigation` (pinned). Pin updates `pinned_organization_id` on `GET/PUT /auth/me` and the optional bottom-nav / rail / sidebar pinned slot without restart.

## Account entry (D-v4-2)

| Path | When | Helper |
|------|------|--------|
| Bottom nav **Account** tab | Compact Pet Care shell (`<600px`) | `guardianAccountTabLocator()` / `openBottomNavTab('Account')` |
| Leading nav **Account** | Medium+ Pet Care shell (`≥600px`) | `openLeadingNavDestination('Account')` |
| Drawer **Account** row | Compact only (drawer retired ≥600px) | `openExperienceDrawer()` + drawer row |
| Hash fallback | Neither path available | `openAccountFromShell()` → `E2E_NAV_FALLBACK` |

Organisation section switching in Playwright prefers the **workspace toggle** over the drawer (`ExperiencePage.openDrawerOrgView()`).

## Fostering session detail (session-detail-view-eec3)

Canonical spec: [session-detail-view.md](/docs/domains/fostering/features/session-detail-view.md).

| Lens | Route | Ready locator (after `waitForFlutterRoutePattern`) |
|------|-------|-----------------------------------------------------|
| Shelter operator / observer | `/o/orgs/:orgId/sessions/:placementId` | `Key('fostering_session_detail_body')` visible |
| Foster participant | `/pet/:petId/fostering-session` | `Key('fostering_session_detail_body')` visible |
| Legacy redirect | `/o/orgs/:orgId/placements/:placementId/session` | Redirects to shelter route |

Entry helpers:

- Org pet profile → `Key('open_fostering_session_button')` or `Key('view_fostering_session_button')`
- Foster pet profile → `Key('view_fostering_session_button')`
- Pending invite card → tap row → foster session route

Action buttons use `Key('session_action_<action_key>')` (e.g. `session_action_confirm_foster_start`).

## TODO (next candidates)

- `pet-list.openVets`, `help.goBack`, `notifications.expectBadgeVisible` throw paths
- Bilingual nav labels in `goHome()` (`Home` / `Accueil`)
