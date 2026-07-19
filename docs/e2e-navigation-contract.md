# E2E navigation contract

Playwright page-object **action methods** (open, navigate, goBack) must not return until:

1. The **expected route pattern** matches (`waitForFlutterRoutePattern`), and
2. The page-specific **ready locator** is visible (`expectLoaded` or equivalent).

Route wait alone is insufficient: Flutter web can update the hash before the semantics tree and widgets are interactive.

## Fallback pattern

When shell detection or drawer clicks fail, call `navigateWithShellFallback()` in `e2e/playwright/support/flutter.ts`. It hash-navigates directly, waits for the route, runs `readyFn`, and logs `E2E_NAV_FALLBACK` with a fixed JSON payload for CI grep.

Use fallback **only** after the normal path fails. Healthy localhost runs should emit **zero** fallback warnings.

## TODO (next candidates)

- `pet-list.openVets`, `help.goBack`, `notifications.expectBadgeVisible` throw paths
- Bilingual nav labels in `goHome()` (`Home` / `Accueil`)
