---
title: E2E navigation contract
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-21
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

After API seeding, the guardian home `DueEventsSection` does not refresh until the screen remounts. Use `PetListPage.refreshByRemount()` before asserting due entries on `/g/home`. The events-screen assertion in #216 was a temporary workaround.

## Guardian compact bottom nav (D-v4-1)

Viewport **&lt;600px** exposes the five-tab `GuardianBottomNavigation` bar (`Key('guardian_bottom_navigation')`).

| Tab label (EN) | Route | Ready locator (after `waitForFlutterRoutePattern`) |
|--------------|-------|-----------------------------------------------------|
| Today | `/g/home` | `GuardianDashboardPage.careRegion()` or My Pets region |
| Pets | `/g/pets` | `All Pets` / `Tous les animaux` footer or pet list section |
| Care | `/g/events` | `HealthDashboardPage.expectLoaded()` |
| Fostering | `/g/fostering` | `Fostering Sessions` / `Sessions d'accueil` heading |
| Account | `/account` | Account section rows (see account screen tests) |

Page object: `GuardianDashboardPage.openBottomNavTab(label)`, `openFosteringViaBottomNav()`.

Selector order for tabs: `getByRole('button', { name })` → `getByRole('tab', { name })` (Flutter 3.44 semantics).

## Workspace toggle (D-v4-3)

Section roots (`/g/home`, `/o/orgs`, `/account`) show `ExperienceWorkspaceToggle` (`Key('experience_workspace_toggle')`) instead of a back arrow.

| Action | Locator | Post-action ready |
|--------|---------|-------------------|
| Assert visible | `GuardianDashboardPage.expectWorkspaceToggleVisible()` | Toggle pill or `Choose your workspace` semantics |
| Open menu | `openWorkspaceMenu()` | Menu items `My Pets` / `Shelter` (`experience_workspace_menu_*` keys in widget tests) |
| Switch to Shelter | `selectWorkspaceMenuItem(/^Shelter$|^Refuge$/i)` | `/o/orgs` + `OrganizationListPage.expectLoaded()` |
| Switch to Guardian | `selectWorkspaceMenuItem(/^My Pets$|^Mes animaux$/i)` | `/g/home` + dashboard care region |

Shelter menu item appears only when org membership makes shelter access eligible (seed with `createOrganization` before login).

## TODO (next candidates)

- `pet-list.openVets`, `help.goBack`, `notifications.expectBadgeVisible` throw paths
- Bilingual nav labels in `goHome()` (`Home` / `Accueil`)
