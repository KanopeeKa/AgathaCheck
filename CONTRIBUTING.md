---
title: Contributing to Agatha Track
owner: Documentation Team
audience: human
status: active
last_updated: 2026-09-29
tags: [contributing,workflow]
---
# Contributing to Agatha Track

Thank you for contributing. This project uses **trunk-based development** on `main`, with **integration branches** for multi-agent sprint work.

## Branch strategy

| Situation | Target branch |
|-----------|---------------|
| Single developer / single agent, one domain | PR directly to `main` |
| One request spawning **multiple parallel agents** | `cursor/sprint-<N>-<topic>-integration-13e3` → agents merge there → **one PR** to `main` |

Rationale: batching reduces repeated CI on `main` as coverage grows. See `.cursor/rules/merge-policy.mdc` and `.cursor/rules/agent-coordination.mdc`.

## Before you start

1. Read `docs/architecture/modularity.md` and `AGENTS.md`.
2. Cursor rules in `.cursor/rules/` encode project standards for agents and humans.

## Avoiding branch conflicts

Conflicts are common when multiple changes land on `main`. **Always sync before push:**

```bash
git fetch origin main
git rebase origin/main    # preferred for linear history
# resolve any conflicts, then:
git push -u origin <your-branch>
```

If you are unsure whether `main` moved while you worked, run the fetch + rebase step again before every push.

## Pre-push checklist

```bash
./scripts/pre-push.sh
```

For faster iteration during development, use `./scripts/pre-push-changed.sh` (runs a subset based on changed files). See `/pre-push-verify` skill and `docs/agent-efficiency/plans/agent-efficiency-plan.md`.

Governance gates in `pre-push.sh` include `scripts/check_care_item_boundary.sh`, which keeps the `care_item` leaf module (application/domain/data and shared completion UI) from importing other Flutter features — see care-next-occurrence plan EX-10.

Manual breakdown if needed:

```bash
cd server && npm ci && npm audit --audit-level=high && npx jest --env=node --forceExit
cd flutter_app && flutter pub get && dart run build_runner build --delete-conflicting-outputs
cd flutter_app && flutter analyze --no-fatal-warnings --no-fatal-infos
cd flutter_app && flutter test --concurrency=1 --exclude-tags=integration
dart format flutter_app/lib flutter_app/test
node scripts/check_file_size.js && node e2e/scripts/check_bdd_coverage.js
```

## Agent workflow

- Domain map: `docs/architecture/index.md`
- Skills: `.cursor/skills/` (split screens, BDD, spawn agents, security audit, pre-push)
- Parallel sprints: `docs/agent-efficiency/prompt-templates.md`
- Babysit merge-ready PRs: `/babysit` command (lightweight)
- Atomic PRs (one outcome, snag ladder): `docs/agent-efficiency/atomic-pr-policy.md`
- Autonomous PR + multi-phase plans: `docs/agent-efficiency/autonomous-pr-policy.md` (`/babysit-plus` skill, `/execute-plan` skill)

## Atomic PRs

**One PR = one verifiable outcome** (describe it in one sentence). Cross-domain changes are fine when they serve that outcome (e.g. UI + API + E2E for one flow). Split independent outcomes into stacked PRs.

**Snags:** fix trivial same-file issues (≤15 lines, no behavior change) in the PR; otherwise open a micro-PR or a debt issue — no silent deferrals. Full policy: [docs/agent-efficiency/atomic-pr-policy.md](docs/agent-efficiency/atomic-pr-policy.md).

## Pull request expectations

Use the PR template checklist. In summary:

| Change type | Requirement |
|---|---|
| Node route | Jest tests |
| Flutter widget | Widget test in mirrored `test/features/` path |
| User journey | Gherkin scenario + Playwright spec with `@bdd` comment |
| Security fix | No raw errors in 5xx; audit clean for high+ |
| Refactor | Reduce file size if touching files >500 lines; update `docs/debt/refactoring-log.md` |

## CI gates on `main`

**Gate contract (blocking vs advisory, UAT/PROD rules):** [docs/pipelines/ci-cd-gates.md](docs/pipelines/ci-cd-gates.md)

**Governance commands, universes, and thresholds:** [docs/agent-efficiency/governance-gates.md](docs/agent-efficiency/governance-gates.md) (must match the scripts; fixture tests prove each gate fails on a deliberate violation).

**Branch protection:** confirming GitHub required checks (`ci-gate / CI passed`, CodeQL) is a **manual human step** — agents cannot read repository settings (see governance-gates doc).

- Flutter analyze, format, and parallel domain test shards (matrix from `flutter_app/test/ci_shards.json`; `node scripts/ci/flutter-shards.mjs check` proves every active test file is owned) + merged domain coverage
- Flutter integration test (blocking)
- Node Jest tests + server architecture tests (`server/test/architecture/`)
- `npm audit --audit-level=high` (server + e2e)
- CodeQL (JavaScript)
- `dart format --set-exit-if-changed` (Flutter code only, blocks merge)
- Documentation validation: `bash scripts/validate_docs.sh --strict`
- ESLint ratchet on active server code: `node scripts/validate_eslint.js`
- Frozen domain boundaries: `bash scripts/check_frozen_domain_boundaries.sh`
- Cross-feature import gate: `node scripts/check_feature_imports.js`
- Flutter domain line coverage ≥ 8% (`merge_flutter_coverage.sh` / `check_domain_coverage.js`; policy target 70% — see `docs/engineering/active-codebase-baseline/flutter-domain-coverage-threshold.json`)
- Backend line coverage ratchet for active `server/lib`, `server/services`, and `server/routes` (`server/scripts/check_coverage_ratchet.js`)
- BDD scenario mapping gate: `node e2e/scripts/check_bdd_coverage.js` (blocking; gate is 68% of gated active scenarios — use `--report-only` locally for counts only)
- Hand-written file size ≤ 500 lines (`scripts/check_file_size.js`; grandfather ratchet for legacy monoliths)
- Coverage artifacts: full Flutter lcov + Jest Istanbul (report-only beyond domain gate)

## E2E and UAT

- Full Playwright suite: **Pre-UAT E2E** on merge to `main` (`pre-uat-e2e.yml`); UAT deploy is HTTP smoke only (`deploy-uat.yml`). Weekly non-blocking cron: `e2e.yml`.
- `@smoke` tests run against live UAT and include axe accessibility checks (critical + serious).
- Weekly non-blocking E2E cron on `main` (see `.github/workflows/e2e.yml`).

## Running E2E locally

```bash
./e2e/scripts/run-local.sh
```

See `e2e/README.md` for details.

## Debt and deferrals

- Refactoring uncertainty or deferrals → `docs/debt/debt.md`
- Sprint refactor plan → `docs/debt/refactoring-log.md`
