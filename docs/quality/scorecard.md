# Quality scorecard

Living metrics for Agatha Track quality. Update when CI or test counts change materially.

**Last updated:** 2026-07-08 (Sprint 3 complete — all 8 items done)

---

## Test counts

| Layer | Count | Gate |
|---|---:|---|
| Flutter unit/widget | 449 | CI on `main` |
| Flutter integration | 1 flow | CI on `main` (blocking) |
| Node Jest | 544 | CI on `main` |
| Playwright E2E | 31 | UAT deploy |
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
| `dart format --set-exit-if-changed` | Yes |

## Coverage

| Layer | Status |
|---|---|
| Flutter domain (`lib/**/domain/**`) | **65% line coverage gate** (CI) |
| Flutter lcov (full app) | CI artifact |
| Jest Istanbul | CI artifact (report-only) |

Domain gate: `flutter_app/scripts/check_domain_coverage.js` (runs after `run_tests_ci.sh` merges per-file lcov). Repository interfaces with no executable lines are excluded automatically.

## Modularity debt (files >500 lines)

| File | Lines | Sprint |
|---|---:|---|
| `pet_form_screen.dart` | 464 | Sprint 2 (was 929) — Done |
| `server/lib/auth_routes.dart` | 14 | Sprint 3 — Done (PR #94; was 769) |
| `server/routes/healthEntries.js` | 541 | Sprint 4 |

See `docs/refactoring-log.md` for full sprint plan.

## npm audit (server)

Run `cd server && npm audit` locally. CI blocks **high** and **critical** (clean as of 2026-07-07 after bcrypt 6 / uuid 11 upgrade).

---

## Changelog

| Date | Change |
|---|---|
| 2026-07-08 | Sprint 3 complete; Flutter tests 449; Playwright E2E 31; auth_routes.dart → 14 lines (PR #94) |
| 2026-07-07 | Sprint 3.1–3.3: screen splits merged; Flutter tests 442 |
| 2026-07-07 | Sprint 2.9: Flutter domain coverage gate (65%) |
| 2026-07-07 | Initial scorecard; Plans A+B governance and CI hardening |
