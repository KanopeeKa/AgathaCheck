# CI test depth and gate remediation

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `ci-test-depth-abc9` |
| **title** | CI test depth, domain-scoped PR shards, Pre-UAT manifest hygiene |
| **author** | Cloud agent |
| **created** | 2026-08-03 |
| **base_branch** | `cursor/ci-test-depth-integration-abc9` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Close the gap between BDD mapping metrics and real test execution: add depth/execution scorecard, align PR CI Flutter shard selection with touched domains, include all Playwright specs in Pre-UAT shards, deepen org v2 and orphan tests, and fix stale CI/CD documentation.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-08-03T18:45:00Z |
| **approved_until** | 2026-08-05T18:45:00Z |
| **control_issue** | #558 |
| **content_hash** | from snapshot |
| **autonomy** | `active` |

**Grant keyword:** Standing grant — user chat 2026-08-03 (full /execute-plan, all phases, auto-merge, spawn when possible)

---

## Phases

### Phase F0 — Doc truth and contracts

| Field | Value |
|-------|-------|
| **id** | `F0` |
| **branch** | `cursor/ci-test-depth-f0-docs-abc9` |
| **exit_checklist** | `governance` |

**allowed_paths:** `docs/**`, `AGENTS.md`, `CONTRIBUTING.md`, `.cursor/rules/agent-core.mdc`, `.cursor/rules/testing.mdc`, `.cursor/skills/pre-push-verify/SKILL.md`, `e2e/README.md`, `.agents/plans/**`

**Scope:** Fix gate numbers (150/241), document PR shard selection model, supersede banners on stale docs, refresh bdd-journey-matrix J7b.

**Exit criteria:**
- [ ] No doc says BDD gate ≥105 without pointing to live script
- [ ] `ci-cd-gates.md` documents stack-level vs shard-level scope (target F2)
- [ ] Superseded banners on coordinator plan + canary deploy-path sections

---

### Phase F1 — Quality metrics tooling

| Field | Value |
|-------|-------|
| **id** | `F1` |
| **branch** | `cursor/ci-test-depth-f1-metrics-abc9` |
| **exit_checklist** | `governance` |

**allowed_paths:** `e2e/scripts/**`, `scripts/check_bdd_priority_tags.js`, `.github/workflows/_reusable-test.yml`, `docs/quality/scorecard.md`, `.agents/plans/**`

**Scope:** `check_test_quality.js`, `validate-shard-manifest.mjs`, wire into governance CI + pre-push; move `check-smoke-tags` to CI.

**Exit criteria:**
- [ ] D1–D4 metrics reported in governance job
- [ ] Orphan spec detection fails CI (allowlist `uat-auth-warmup`)
- [ ] `check-smoke-tags.mjs` runs in CI governance

---

### Phase F2 — PR domain-scoped Flutter shards

| Field | Value |
|-------|-------|
| **id** | `F2` |
| **branch** | `cursor/ci-test-depth-f2-ci-scope-abc9` |
| **exit_checklist** | `governance` |

**allowed_paths:** `scripts/ci/**`, `.github/workflows/ci.yml`, `.github/workflows/_reusable-ci-gate.yml`, `.github/workflows/_reusable-flutter-coverage.yml`, `docs/ci-cd-gates.md`, `.agents/plans/**`

**Scope:** Extend `ci-scope-lib.sh` to emit `run_shards[]`; per-shard job `if`; coverage merge for partial shards; Jest path scoping on PR.

**Exit criteria:**
- [ ] Org-only PR runs `flutter-test-org` shard only (+ analyze, build-web, canary)
- [ ] `ci-gate` accepts skipped shards per scope JSON
- [ ] `ci-scope.test.js` covers domain→shard mapping

---

### Phase F3 — Pre-UAT shard manifest + rebalance

| Field | Value |
|-------|-------|
| **id** | `F3` |
| **branch** | `cursor/ci-test-depth-f3-shards-abc9` |
| **exit_checklist** | `governance` |

**allowed_paths:** `e2e/scripts/shard-files.mjs`, `e2e/scripts/run-ci-shard.mjs`, `.github/workflows/pre-uat-e2e.yml`, `.github/workflows/e2e.yml`, `e2e/README.md`, `docs/ci-cd-gates.md`, `.agents/plans/**`

**Scope:** Add all orphan specs to manifest (12 shards); rebalance heavy groups; update workflow matrix.

**Exit criteria:**
- [ ] `validate-shard-manifest.mjs` passes with 0 orphans
- [ ] 12-shard manifest; workflows use shard_total 12
- [ ] All org v2 spec files in Pre-UAT manifest

---

### Phase F4 — Org v2 test deepening (spawn)

| Field | Value |
|-------|-------|
| **id** | `F4` |
| **branch** | `cursor/ci-test-depth-f4-org-tests-abc9` |
| **spawn_allowed** | `true` |
| **exit_checklist** | `default` |

**allowed_paths:** `e2e/playwright/tests/organisation.*`, `e2e/playwright/pages/organization*.ts`, `flutter_app/test/bdd/features/organisation_*`, `flutter_app/test/bdd/features/admin_contacts.feature`, `flutter_app/test/bdd/features/fostering_sessions.feature`, `flutter_app/test/bdd/features/pet_screen_filters.feature`, `flutter_app/test/features/organization/**`, `server/test/organizations/**`, `docs/quality/bdd-journey-matrix.md`, `.agents/plans/**`

**Scope:** Replace skeleton Playwright tests; add redacted pet Gherkin + Jest + E2E; deepen admin-contacts UI; tag org profile `@smoke-ci`.

**Exit criteria:**
- [ ] No S0 skeletons in org v2 Playwright specs
- [ ] Redacted associate pet scenario mapped and tested
- [ ] At least one org v2 UI journey `@smoke-ci`

---

### Phase F5 — General widening + scorecard

| Field | Value |
|-------|-------|
| **id** | `F5` |
| **branch** | `cursor/ci-test-depth-f5-widen-abc9` |
| **exit_checklist** | `default` |

**allowed_paths:** `e2e/playwright/tests/fostering.platform.spec.ts`, `e2e/playwright/tests/foster.onboarding.spec.ts`, `e2e/playwright/tests/guardian.dashboard.spec.ts`, `e2e/playwright/tests/experience.navigation.spec.ts`, `docs/quality/**`, `docs/architecture/index.md`, `.agents/plans/**`

**Scope:** Ensure orphaned non-org specs have real tests or documented deferral; update scorecard from quality script; architecture index E2E list.

**Exit criteria:**
- [ ] Orphan specs (non-uat-warmup) have non-skeleton tests or `@skip-ci` debt note
- [ ] `scorecard.md` reflects D1–D4 metrics

---

### Phase F6 — Integration to main

| Field | Value |
|-------|-------|
| **id** | `F6` |
| **branch** | `cursor/ci-test-depth-integration-abc9` |
| **exit_checklist** | `governance` |

**allowed_paths:** `.agents/plans/**`, `docs/refactoring-log.md`

**Scope:** Single PR integration → main; `./scripts/pre-push.sh` green.

**Exit criteria:**
- [ ] Integration PR merged to main
- [ ] All phase PRs merged to integration

---

## Runtime state

```yaml
autonomy: active
current_phase: F1
last_completed_phase: F0
halt_reason: null
next_action: "start phase F1: checkout cursor/ci-test-depth-f1-metrics-abc9"
artifact_ref:
  branch: cursor/ci-test-depth-integration-abc9
  plan_path: .agents/plans/ci-test-depth-abc9.md
  plan_commit: 9f2c68ec67e8ef645a155446a4dcaffd7fa7db60
  snapshot_path: .agents/plans/ci-test-depth-abc9.snapshot.json
  snapshot_commit: 9f2c68ec67e8ef645a155446a4dcaffd7fa7db60
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
