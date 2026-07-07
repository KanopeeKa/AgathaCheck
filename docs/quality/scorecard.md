# Quality scorecard

Living metrics for Agatha Track quality. Update when CI or test counts change materially.

**Last updated:** 2026-07-07 (Sprint 2 in progress)

---

## Test counts

| Layer | Count | Gate |
|---|---:|---|
| Flutter unit/widget | 431+ | CI on `main` |
| Flutter integration | 1 flow | CI on `main` (blocking) |
| Node Jest | 544 | CI on `main` |
| Playwright E2E | 15 | UAT deploy |
| BDD Gherkin scenarios | 161 | Spec (hybrid — Playwright executor) |
| BDD → Playwright coverage | ~9% | Target 25% (Sprint 2) |

## CI security

| Check | Where | Blocks `main`? |
|---|---|---|
| `npm audit --audit-level=high` | server, e2e | Yes |
| CodeQL (JavaScript) | `.github/workflows/codeql.yml` | Yes (default query suite) |
| Dependabot | weekly PRs | Via review |
| axe (critical + serious) | UAT `@smoke` Playwright | UAT `prod-ready` gate |

## Static analysis

| Check | Blocks `main`? |
|---|---|
| `flutter analyze` | Yes |
| `dart analyze lib` (server) | Yes |
| `dart format --set-exit-if-changed` | **Warn only** (Sprint 1) |

## Coverage

| Layer | Status |
|---|---|
| Flutter lcov | CI artifact (report-only) |
| Jest Istanbul | CI artifact (report-only) |
| Threshold enforcement | Deferred to Sprint 2 |

## Modularity debt (files >500 lines)

| File | Lines | Sprint |
|---|---:|---|
| `pet_form_screen.dart` | 553 | Sprint 2 (was 929) |
| `health_entry_form_screen.dart` | 425 | Sprint 2 (was 756) |
| `pet_detail_screen.dart` | 639 | Sprint 3 |
| `health_dashboard_screen.dart` | 628 | Sprint 3 |
| `my_details_screen.dart` | 608 | Sprint 3 |
| `server/lib/auth_routes.dart` | 736 | Sprint 3 |
| `server/routes/healthEntries.js` | 541 | Sprint 4 |

See `docs/refactoring-log.md` for full sprint plan.

## npm audit (server)

Run `cd server && npm audit` locally. CI blocks **high** and **critical** (clean as of 2026-07-07 after bcrypt 6 / uuid 11 upgrade).

---

## Changelog

| Date | Change |
|---|---|
| 2026-07-07 | Initial scorecard; Plans A+B governance and CI hardening |
