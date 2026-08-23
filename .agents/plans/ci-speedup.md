# CI speedup — path scope, shard balance, caching, merge audit

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `ci-speedup` |
| **title** | CI speedup without gate regression |
| **author** | Cloud agent |
| **created** | 2026-07-23 |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Speed up PR CI via runner setup caching, Flutter shard rebalancing, path-scoped job skipping (shared rules with `pre-push-changed.sh`), and a non-blocking full-suite audit on `main` every **12 merges** with agent dispatch on failure — without weakening blocking gates or UAT prod-ready contract.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-07-23T14:00:00Z |
| **approved_until** | 2026-07-25T14:00:00Z |
| **control_issue** | #285 |
| **content_hash** | from snapshot |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous ci-speedup` (human go on 2026-07-23)

---

## Phases

### Phase 1 — Runner setup caching

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/ci-speedup-phase1-cache-b697` |
| **exit_checklist** | `governance` |

**allowed_paths:** `.github/actions/**`, `.github/workflows/_reusable-e2e-local.yml`, `.github/workflows/_reusable-flutter-test-shard.yml`, `.github/workflows/_reusable-flutter-coverage.yml`, `.agents/plans/**`

**Scope:** Playwright browser cache composite; lcov apt cache composite; wire into E2E canary + Flutter shards.

**Exit criteria:**

- [ ] Composites used by E2E local + Flutter shard/coverage workflows
- [ ] No change to test commands or gate thresholds
- [ ] `docs/pipelines/ci-cd-gates.md` unchanged (no new blocking jobs)

### Phase 2 — Rebalance `rest` Flutter shard

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/ci-speedup-phase2-shards-b697` |

**allowed_paths:** `flutter_app/scripts/run_tests_ci_shard.sh`, `flutter_app/scripts/merge_flutter_coverage.sh`, `.github/workflows/ci.yml`, `scripts/ci/assert-ci-gate.sh`, `.github/workflows/_reusable-ci-gate.yml`, `docs/pipelines/ci-cd-gates.md`, `.agents/plans/**`

**Scope:** Split `rest` → `rest-a` / `rest-b`; update merge + ci-gate lists.

### Phase 3 — Path-scoped PR CI

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/ci-speedup-phase3-scope-b697` |

**allowed_paths:** `scripts/ci/ci-scope-lib.sh`, `scripts/ci/resolve-ci-scope.sh`, `scripts/pre-push-changed.sh`, `.github/workflows/ci.yml`, `scripts/ci/assert-ci-gate.sh`, `.github/workflows/_reusable-ci-gate.yml`, `docs/pipelines/ci-cd-gates.md`, `scripts/ci/ci-scope.test.js`, `.agents/plans/**`

### Phase 4 — Conditional ancillary gates + 12-merge full audit

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/ci-speedup-phase4-audit-b697` |

**allowed_paths:** `.github/workflows/**`, `scripts/ci/**`, `docs/pipelines/ci-cd-gates.md`, `scripts/pre-push-changed.sh`, `.agents/plans/**`

**Scope:** Conditional npm audit / integration; `ci-full-audit.yml` on main every 12 merges; agent issue spawn on failure.

---

## Runtime state

```yaml
autonomy: active
current_phase: "1"
last_completed_phase: null
halt_reason: null
next_action: implement phase 1 caching
artifact_ref:
  branch: cursor/ci-speedup-phase1-cache-b697
  plan_path: .agents/plans/ci-speedup.md
  snapshot_path: .agents/plans/ci-speedup.snapshot.json
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
