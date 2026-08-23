---
title: Quality scorecard
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [quality, metrics]
---
# Quality scorecard

Living metrics for Agatha Track quality. Update when CI or test counts change materially.

**Last updated:** 2026-08-04 (org-ux-v3 phase 11 hardening)

---

## Test counts

| Layer | Count | Gate |
|---|---:|---|
| Flutter unit/widget | 449 | CI on `main` |
| Flutter integration | 1 flow | CI on `main` (blocking) |
| Node Jest | 544 | CI on `main` |
| Playwright E2E | 79+ | Pre-UAT E2E (12-shard, post-merge) |
| BDD Gherkin scenarios | 266 | Spec (hybrid — Playwright executor) |
| BDD → Playwright coverage | **70.7% (188/266)** | CI gate **180/266** — `e2e/scripts/check_bdd_coverage.js` |
| Test quality scorecard | D1–D6 metrics | `node e2e/scripts/check_test_quality.js --report-only` (CI governance) |
| Pre-UAT shard orphans | **0** | `e2e/scripts/validate-shard-manifest.mjs` |
| @smoke-ci PR canary | **5** | `ci-e2e-canary` job |

## CI security

| Check | Where | Blocks `main`? |
|---|---|---|
| `npm audit --audit-level=high` | server, e2e | Yes |
| CodeQL (JavaScript) | `.github/workflows/codeql.yml` | Yes (default query suite) |
| Dependabot | weekly PRs | Via review |
| axe (critical + serious) | `uat-live-e2e.yml` (advisory) | No — not prod-ready deploy gate |

## Static analysis

| Check | Blocks `main`? |
|---|---|
| `flutter analyze` | Yes |
| BDD scenarios mapped ≥ 180/266 | Yes |
| Hand-written file size ≤ 500 lines | Yes (grandfather ratchet) |

## Coverage

| Layer | Status |
|---|---|
| Flutter domain (`lib/**/domain/**`) | **65% line coverage gate** (CI) |
| Flutter lcov (full app) | CI artifact |
| Jest Istanbul | CI artifact (report-only) |

Domain gate: `flutter_app/scripts/check_domain_coverage.js` (runs after `run_tests_ci.sh` merges per-file lcov). Repository interfaces with no executable lines are excluded automatically.

## Modularity debt (grandfathered >500 lines)

CI blocks **new** files above 500 lines. **`scripts/file-size-allowlist.json` is empty** as of Sprint 5.4b — all legacy monoliths split.

| File | Lines | Sprint |
|---|---:|---|
| `organization_providers.dart` | 6 (barrel) | 5.4b — Done |
| `landing_screen.dart` | 219 | 5.4b — Done |
| `other_event_form_screen.dart` | 301 | 5.4b — Done |
| `health_entry_card.dart` | 190 | 5.4b — Done |
| `placements_routes.dart` | 12 (composer) | 5.4 — Done |
| `pet_foster_placement_section.dart` | 178 | 5.4 — Done |
| `placementsRouter.js` | 1 (re-export) | 5.4 — Done |
| `pet_form_screen.dart` | 464 | Sprint 2 — Done |
| `server/routes/healthEntries.js` | 1 (re-export) | Sprint 4 — Done |

See `docs/quality/review-2026-07-08.md` and `docs/debt/refactoring-log.md`.

## npm audit (server)

Run `cd server && npm audit` locally. CI blocks **high** and **critical** (clean as of 2026-07-07 after bcrypt 6 / uuid 11 upgrade).

---

## Changelog

| Date | Change |
|---|---|
| 2026-08-04 | Organisation UX v3 phase 11: BDD **188/266** mapped; gate ratchet **180/266**; EN+FR l10n parity (1402 keys); `org-v3-demo` seed + E2E privacy/discover helpers |
| 2026-08-03 | ci-test-depth-abc9 F0: BDD **177/241** mapped; gate **150/241**; Pre-UAT vs deploy-tier doc alignment |
| 2026-08-03 | ci-test-depth-abc9: D1–D6 scorecard, 12-shard Pre-UAT manifest, PR domain Flutter shards, org v2 E2E depth + redacted pet |
| 2026-08-02 | Organisation v2 8a–9: BDD 167/231 mapped; gate ratchet **150/231**; admin contacts + permissions E2E |
| 2026-07-08 | Sprint 5.5–5.6: GDPR export completeness; @P0/@P1/@P2 on all 161 scenarios + CI gate |
| 2026-07-08 | Sprint 5.4b: all 5 remaining monoliths split; grandfather allowlist cleared |
| 2026-07-08 | Sprint 5.4: placements split; grandfather allowlist 8→5 |
| 2026-07-08 | Sprint 5.1: review doc; CI BDD + file-size gates; integration-branch policy |
| 2026-07-08 | Sprint 4.3 BDD gate met: 81/161 scenarios mapped; Playwright 79 tests |
| 2026-07-08 | Sprint 4.3 BDD journey matrix; 50% gate = 81/161 scenarios; Playwright 47 |
| 2026-07-08 | Sprint 3 complete; Flutter tests 449; Playwright E2E 31; auth_routes.dart → 14 lines (PR #94) |
| 2026-07-07 | Sprint 3.1–3.3: screen splits merged; Flutter tests 442 |
| 2026-07-07 | Sprint 2.9: Flutter domain coverage gate (65%) |
| 2026-07-07 | Initial scorecard; Plans A+B governance and CI hardening |
