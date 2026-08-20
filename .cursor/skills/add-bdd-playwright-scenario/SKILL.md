---
name: add-bdd-playwright-scenario
description: Map a Gherkin scenario to a Playwright E2E test with @bdd header, page objects, and BDD coverage gate. Use when implementing BDD coverage, adding E2E for a feature file, or Sprint 6+ org/guardian journeys.
paths:
  - e2e/**
  - flutter_app/test/bdd/**
---

# Add BDD → Playwright scenario

## Read first

- Scenario text: `flutter_app/test/bdd/features/<feature>.feature`
- Journey context: `docs/quality/bdd-journey-matrix.md` (relevant section only)
- `e2e/README.md`

## Steps

1. **Pick scenario(s)** — copy exact `Scenario:` title from Gherkin (case-sensitive match required).
2. **Check priority tag** — scenario must have `@P0`, `@P1`, or `@P2` (CI gate).
3. **Create or extend spec** in `e2e/playwright/tests/<name>.spec.ts`:
   ```ts
   /**
    * @bdd pet_profiles.feature
    * Scenario: Creating a new pet with required fields
    */
   ```
   - Titles in `@bdd` block must **exactly** match Gherkin `Scenario:` lines.
4. **Page objects** — add/reuse under `e2e/playwright/pages/`; never duplicate selectors inline.
5. **API seeding** — use `e2e/playwright/support/api.ts` helpers; coordinate if extending shared fixtures (foundation agent first in parallel sprints).
6. **Flutter web** — call `enableFlutterAccessibility()` before UI interaction (`support/flutter.ts`).
7. **Selectors:** `getByRole` → `getByLabel` / aria-label → `getByText`.
8. **Smoke / axe** — add `@smoke` to test title only for P0 guardian paths on UAT.
9. **Verify gate:**
   ```bash
   node e2e/scripts/check_bdd_coverage.js
   node scripts/check_bdd_priority_tags.js
   ```
10. **UI check (when spec touches Flutter journeys)** — If the scenario adds or changes visible UI, run **`/ui-check`** on affected screens before opening the PR.
11. **Update matrix** — add row in `docs/quality/bdd-journey-matrix.md` for the scenario.

## Parallel sprint rules

- One agent per spec file / feature area.
- Never edit `api.ts` concurrently — foundation agent merges first.
- See `/spawn-sprint-agents` for ownership matrix.

## Do not

- Change Gherkin scenario titles without updating `@bdd` headers.
- Run full Playwright locally unless env is up (`./e2e/scripts/run-local.sh`); coverage script is enough for PR CI.
