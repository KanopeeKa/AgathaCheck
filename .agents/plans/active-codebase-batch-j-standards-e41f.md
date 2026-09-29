---
title: Active codebase Batch J — Measurable, blocking standards
owner: Agent
audience: agent
status: proposed
last_updated: 2026-09-29
---

# active-codebase-batch-j-standards-e41f

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `active-codebase-batch-j-standards-e41f` |
| **roadmap** | [`active-codebase-completion-e41f`](./active-codebase-completion-e41f.md) |
| **base_branch** | `cursor/active-codebase-j-integration-e41f` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **depends on** | Batch D merged. Parallel-eligible with I1 and I2 (scripts, CI and server lint config only). |
| **router risk** | R2 — protocols `testing`, `documentation`; CI edits limited to D9(b) |

## Goal

Finish Package 11 (D6, D7, D23). Every gate measures an explicit, published universe:

- Files missing from coverage count against coverage.
- Lint and size checks cover the active server libraries and services.
- D7 moves from report-only to a ratchet.
- BDD traceability is separated from execution and quality.
- Every checker has a fixture proving it fails on a deliberate violation, and runs in blocking CI.

**CI scope (D9b):** only `.github/workflows/_reusable-test.yml` and `.github/workflows/_reusable-flutter-coverage.yml` may change. Steps can be added or tightened, never removed or loosened.

**Phase overlap note:** phases 1, 2 and 4 each touch `_reusable-test.yml`. They run strictly in sequence.

## Autonomy (filled at bootstrap)

| Field | Value |
|-------|-------|
| **approved_by** | standing grant — roadmap `active-codebase-completion-e41f` |
| **approved_at / approved_until** | set at bootstrap (+48h) |
| **control_issue** | set at bootstrap |

## Runtime

```yaml
autonomy: active
current_phase: "1"
last_completed_phase: null
halt_reason: null
next_action: "bootstrap: create integration branch + control issue, then phase 1"
artifact_ref:
  branch: null
  plan_path: .agents/plans/active-codebase-batch-j-standards-e41f.md
  plan_commit: null
  snapshot_path: .agents/plans/active-codebase-batch-j-standards-e41f.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

### Phase 1 — Coverage denominators and ratchets

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/active-codebase-j1-coverage-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-j-standards-e41f.*
flutter_app/scripts/check_domain_coverage.js
flutter_app/scripts/merge_flutter_coverage.sh
flutter_app/scripts/run_tests_ci.sh
flutter_app/scripts/generate_coverage_helper.*
flutter_app/test/coverage_helper_test.dart
flutter_app/scripts/test/**
server/jest.config.active.cjs
server/scripts/check_coverage_ratchet.js
server/coverage-ratchet.json
scripts/check_coverage_threshold_consistency.test.js
.github/workflows/_reusable-test.yml
.github/workflows/_reusable-flutter-coverage.yml
CONTRIBUTING.md
docs/engineering/active-codebase-baseline/**
```

**forbidden_paths:**

```
server/lib/**
server/routes/**
flutter_app/lib/**
e2e/**
```

**allowed_exceptions:**

```
tests
docs
```

**Acceptance criteria:**

- [ ] **J.1-1** A generated coverage helper imports every eligible Flutter domain file (active features per the manifest, `lib/features/*/domain/**`, not generated), so each one appears in `lcov.info`. A fixture test proves that a domain file with no test lowers the reported coverage instead of being ignored.
- [ ] **J.1-2** The eligible universes for size, lint, Flutter coverage, backend coverage and BDD are published in `docs/engineering/active-codebase-baseline/README.md` §Measured universes, using the same frozen and generated exclusions as the metrics script.
- [ ] **J.1-3** The Flutter domain threshold is re-set from the measured result with missing files counted (D23): it stays 70 if the measurement is at least 70; otherwise it becomes the floored measured value, with a recorded exception and review date. The D.3 consistency test still passes.
- [ ] **J.1-4** Backend: `npx jest --coverage` over active `server/lib`, `server/services` and `server/routes` (frozen roots excluded) runs in CI. `server/coverage-ratchet.json` stores per-area line floors at the measured values, and `server/scripts/check_coverage_ratchet.js` fails CI only when an area drops below its floor. A fixture test shows the drop is detected.

---

### Phase 2 — Lint scope and D7 size ratchet

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/active-codebase-j2-lint-size-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-j-standards-e41f.*
scripts/validate_eslint.js
scripts/validate_eslint.test.js
server/eslint.config.js
server/eslint-baseline.json
scripts/check_file_size.js
scripts/check_file_size.test.js
scripts/file-size-allowlist.json
scripts/test/fixtures/file-size/**
.github/workflows/_reusable-test.yml
docs/engineering/active-codebase-baseline/**
```

**forbidden_paths:**

```
flutter_app/**
e2e/**
server/routes/**
```

**allowed_exceptions:**

```
tests
docs
governance-allowlist
```

**Acceptance criteria:**

- [ ] **J.2-1** `validate_eslint.js` lints all **active** `server/lib/**`, `server/services/**` and `server/routes/**`, excluding frozen roots from the manifest. Today `LINT_PATHS` covers only 4 paths. Existing violations are recorded per rule and file in `server/eslint-baseline.json`; new violations fail, and the baseline only shrinks.
- [ ] **J.2-2** D7 ratchet: `server/lib` and `server/services` become **blocking** for new files over 500 lines and for growth of existing offenders beyond their recorded `maxLines`. Allowlist entries carry `owner`, `reason` and `review_date`, and the check warns when a review date has passed.
- [ ] **J.2-3** The size report classifies Flutter files as screens, widgets, controllers/providers or data, and reports physical and heuristic line counts separately. The published report is refreshed.
- [ ] **J.2-4** Fixture tests cover: a new 501-line file in `server/lib` fails; an allowlisted file growing past `maxLines` fails; an expired `review_date` warns.

---

### Phase 3 — BDD traceability versus execution and quality

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/active-codebase-j3-bdd-quality-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-j-standards-e41f.*
e2e/scripts/check_bdd_coverage.js
e2e/scripts/check_bdd_coverage.test.*
e2e/scripts/fixtures/bdd/**
docs/e2e/**
```

**forbidden_paths:**

```
server/**
flutter_app/lib/**
.github/workflows/**
```

**allowed_exceptions:**

```
tests
docs
```

**Acceptance criteria:**

- [ ] **J.3-1** `check_bdd_coverage.js` reports three separate figures: (a) active scenarios whose title maps to an `@bdd` spec; (b) mapped specs that are actually **scheduled** in the pre-UAT shard manifest (`e2e/scripts/shard-files.mjs`); and (c) skeleton or orphan specs (no `expect`, `test.skip` or `test.fixme`, or a spec with no scenario).
- [ ] **J.3-2** The blocking gate stays at 68% of active **mapped** scenarios (no loosening). Figures (b) and (c) are report-only in this batch, and their current values are recorded in the baseline README.
- [ ] **J.3-3** Frozen scenarios stay excluded via the manifest's `bddFeaturePatterns` and `frozen-e2e-specs.mjs`. Fixture tests cover each category.

---

### Phase 4 — Checker fixtures and blocking CI wiring

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/active-codebase-j4-checker-ci-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-j-standards-e41f.*
scripts/ci/assert-ci-gate.test.js
scripts/ci/**
scripts/test/**
scripts/pre-push.sh
.github/workflows/_reusable-test.yml
docs/agent-efficiency/**
CONTRIBUTING.md
```

**forbidden_paths:**

```
server/lib/**
server/routes/**
flutter_app/lib/**
e2e/playwright/**
```

**allowed_exceptions:**

```
tests
docs
```

**Acceptance criteria:**

- [ ] **J.4-1** Each governance checker has a fixture test that **fails on a deliberate violation**: file size, feature imports, frozen boundaries, transaction ownership (E.3), server direction (H.4/I2.4), docs validation, BDD coverage, the Flutter coverage threshold and the backend coverage ratchet. All of them run in CI.
- [ ] **J.4-2** `scripts/ci/assert-ci-gate.test.js` asserts that docs validation, frozen boundaries, feature imports, file size, ESLint, both coverage gates and the architecture tests are all **blocking** steps in the required CI gate.
- [ ] **J.4-3** `CONTRIBUTING.md` and `docs/agent-efficiency/` list every gate with its command, universe and threshold, and they match the scripts. Verifying GitHub branch protection is documented as a manual human step, because agents cannot read repository settings.

---

### Phase 5 — Integration → main + pre-UAT

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/active-codebase-j-integration-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
**
```

**forbidden_paths:**

```
.github/workflows/deploy-*.yml
```

**allowed_exceptions:**

```
tests
docs
```

**Scope:** open one PR from the integration branch into `main`; `./scripts/pre-push.sh`; `/babysit-uat`; pre-UAT watch; `complete-plan`; `roadmap-set-child`.

**Acceptance criteria:**

- [ ] **J.5-1** The integration → `main` PR is merged by `/babysit-uat`, with every CI job green under the new gates.
- [ ] **J.5-2** Pre-UAT E2E is green on the merge SHA.
- [ ] **J.5-3** The roadmap child status is `merged`, and the Package 11 row reads Done.
