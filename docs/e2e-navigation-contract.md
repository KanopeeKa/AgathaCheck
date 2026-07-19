# E2E navigation contract

Playwright page-object **action methods** (open, navigate, goBack) must not return until:

1. The **expected route pattern** matches (`waitForFlutterRoutePattern`), and
2. The page-specific **ready locator** is visible (`expectLoaded` or equivalent).

Route wait alone is insufficient: Flutter web can update the hash before the semantics tree and widgets are interactive.

## Fallback pattern

When shell detection or drawer clicks fail, call `navigateWithShellFallback()` in `e2e/playwright/support/flutter.ts`. It hash-navigates directly, waits for the route, runs `readyFn`, and logs `E2E_NAV_FALLBACK` with a fixed JSON payload for CI grep.

Use fallback **only** after the normal path fails. Healthy localhost runs should emit **zero** fallback warnings.

## API seed ordering (live UAT)

When seeding via `playwright/support/api.ts` and asserting on the **home pet list**, create data **before** `loginAs` using `testUser.accessToken`. Post-login API creates leave a stale empty list on live UAT (passes on fast localhost).

```ts
const pet = await createPet(baseURL, testUser.accessToken, 'Bella');
await loginAs(page, testUser);
await petList.expectPetVisible(pet.name);
```

For **due events on home** after API seed, call `refreshByRemount()` — the section does not hot-reload. Details: [`docs/e2e/uat-live-operations-runbook.md`](../docs/e2e/uat-live-operations-runbook.md).

## Due events on home (PR C)

After API seeding, the guardian home `DueEventsSection` does not refresh until the screen remounts. Use `PetListPage.refreshByRemount()` before asserting due entries on `/g/home`. The events-screen assertion in #216 was a temporary workaround.

## TODO (next candidates)

- `pet-list.openVets`, `help.goBack`, `notifications.expectBadgeVisible` throw paths
- Bilingual nav labels in `goHome()` (`Home` / `Accueil`)
