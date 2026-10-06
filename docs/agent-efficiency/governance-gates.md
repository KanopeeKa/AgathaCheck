---
title: Governance gates (commands and CI)
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-06
tags: [agent-efficiency, ci, governance]
---

# Governance gates

Blocking gates enforced in CI (`test-suite` / `flutter-coverage` jobs) and locally via `./scripts/pre-push-changed.sh` / `./scripts/pre-push.sh`. Universes and thresholds match `docs/engineering/active-codebase-baseline/README.md` §Measured universes unless noted.

| Gate | Command | Universe | Threshold / semantics | CI job (blocking via `ci-gate`) |
|------|---------|----------|----------------------|----------------------------------|
| Documentation validation | `bash scripts/validate_docs.sh --strict` | `docs/**` placement, links, frontmatter, manifest | Zero errors in `--strict` | `test-suite / Governance` |
| Frozen domain boundaries | `bash scripts/check_frozen_domain_boundaries.sh` | Active `flutter_app/lib`, `server/lib`, `server/routes`, `server/bin` | No imports of manifest-frozen roots | `test-suite / Governance` |
| Cross-feature imports | `node scripts/check_feature_imports.js` | `flutter_app/lib/**` (minus generated + frozen) | R1–R4 identities vs baseline (block-new) | `test-suite / Governance` |
| File size | `node scripts/check_file_size.js` | Hand-written `.dart` in `flutter_app/lib`; `.js` in active server roots | ≤ 500 lines (D7 allowlist ratchet for legacy) | `test-suite / Governance` |
| ESLint ratchet | `node scripts/validate_eslint.js` | Active `server/lib`, `server/services`, `server/routes` | No new violations vs `server/eslint-baseline.json` | `test-suite / ESLint` |
| BDD traceability | `node e2e/scripts/check_bdd_coverage.js` | Active Gherkin scenarios (frozen patterns excluded) | ≥ 68% of **gated** mapped scenarios | `test-suite / Governance` |
| Flutter domain coverage | `bash flutter_app/scripts/merge_flutter_coverage.sh` | `lib/features/*/domain/**` for active features | Line % ≥ threshold in `flutter-domain-coverage-threshold.json` (**8%** measured; policy target **70%**) | `flutter-coverage / Flutter domain coverage` |
| Backend coverage ratchet | `node server/scripts/check_coverage_ratchet.js` | `server/lib`, `server/services`, `server/routes` (frozen routes excluded) | Per-area floors in `server/coverage-ratchet.json` | `test-suite / Backend` |
| Server architecture | `npx jest test/architecture --forceExit` (from `server/`) | Active server tree | E.3 transaction ownership; H.4/I2.4 server direction rules | `test-suite / Backend` |

Each gate has a **fixture test** that fails on a deliberate violation (see `scripts/ci/governance-blocking-steps.mjs` → `fixture` column). `node --test scripts/ci/assert-ci-gate.test.js` asserts these steps stay **blocking** in `.github/workflows/_reusable-test.yml` and `_reusable-flutter-coverage.yml`, and that `ci-gate` still aggregates `test-suite` and `flutter-coverage`.

## Branch protection (manual human step)

Agents and repository files **cannot** read GitHub branch protection or rulesets. A human with admin access must confirm that required checks on `main` include at least:

- `ci-gate / CI passed` (umbrella — covers the gates above)
- `Analyze JavaScript` (CodeQL)

See `docs/pipelines/ci-cd-gates.md` §1 for the maintained check-name table.
