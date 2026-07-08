# Quality scorecard

Living metrics for Agatha Track quality. Update when CI or test counts change materially.

**Last updated:** 2026-07-08 (Sprint 5.1 governance)

---

## Test counts

| Layer | Count | Gate |
|---|---:|---|
| Flutter unit/widget | 449 | CI on `main` |
| Flutter integration | 1 flow | CI on `main` (blocking) |
| Node Jest | 544 | CI on `main` |
| Playwright E2E | 79 | UAT deploy |
| BDD Gherkin scenarios | 161 | Spec (hybrid — Playwright executor) |
| BDD → Playwright coverage | **50.3% (81/161)** | CI gate — `e2e/scripts/check_bdd_coverage.js` |

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
| BDD scenarios mapped ≥ 81/161 | Yes |
| Hand-written file size ≤ 500 lines | Yes (grandfather ratchet) |

## Coverage

| Layer | Status |
|---|---|
| Flutter domain (`lib/**/domain/**`) | **65% line coverage gate** (CI) |
| Flutter lcov (full app) | CI artifact |
| Jest Istanbul | CI artifact (report-only) |

Domain gate: `flutter_app/scripts/check_domain_coverage.js` (runs after `run_tests_ci.sh` merges per-file lcov). Repository interfaces with no executable lines are excluded automatically.

## Modularity debt (grandfathered >500 lines)

CI blocks **new** files above 500 lines. Legacy monoliths are ratcheted in `scripts/file-size-allowlist.json` — target Sprint 5.4 splits.

| File | Lines | Sprint |
|---|---:|---|
| `placements_routes.dart` | 663 | 5.4 |
| `pet_foster_placement_section.dart` | 653 | 5.4 |
| `organization_providers.dart` | 607 | 5.4+ |
| `server/lib/routes.dart` | 591 | 5.4+ |
| `landing_screen.dart` | 576 | 5.4+ |
| `other_event_form_screen.dart` | 565 | 5.4+ |
| `placementsRouter.js` | 518 | 5.4 |
| `health_entry_card.dart` | 505 | 5.4+ |
| `pet_form_screen.dart` | 464 | Sprint 2 — Done |
| `server/lib/auth_routes.dart` | 14 | Sprint 3 — Done |
| `server/routes/healthEntries.js` | 1 (re-export) | Sprint 4 — Done |

See `docs/quality/review-2026-07-08.md` and `docs/refactoring-log.md`.

## npm audit (server)

Run `cd server && npm audit` locally. CI blocks **high** and **critical** (clean as of 2026-07-07 after bcrypt 6 / uuid 11 upgrade).

---

## Changelog

| Date | Change |
|---|---|
| 2026-07-08 | Sprint 5.1: review doc; CI BDD + file-size gates; integration-branch policy |
| 2026-07-08 | Sprint 4.3 BDD gate met: 81/161 scenarios mapped; Playwright 79 tests |
| 2026-07-08 | Sprint 4.3 BDD journey matrix; 50% gate = 81/161 scenarios; Playwright 47 |
| 2026-07-08 | Sprint 3 complete; Flutter tests 449; Playwright E2E 31; auth_routes.dart → 14 lines (PR #94) |
| 2026-07-07 | Sprint 3.1–3.3: screen splits merged; Flutter tests 442 |
| 2026-07-07 | Sprint 2.9: Flutter domain coverage gate (65%) |
| 2026-07-07 | Initial scorecard; Plans A+B governance and CI hardening |
