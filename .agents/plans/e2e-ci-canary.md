# Plan — E2E fail-fast canary (`e2e-ci-canary`)

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `e2e-ci-canary` |
| **title** | E2E fail-fast canary (@smoke-ci PR gate + @smoke-uat hardening) |
| **author** | Cursor cloud agent |
| **created** | 2026-07-19 |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Add a fast PR Playwright canary (`@smoke-ci`, retries 0), harden UAT live smoke (`@smoke-uat`, retries 0), and tune full localhost shard retries — without removing the 10-shard UAT prod-ready contract. Canonical spec: `docs/e2e-ci-canary-plan.md`.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-07-19T22:15:00Z |
| **approved_until** | 2026-07-21T22:15:00Z |
| **control_issue** | Pending GitHub issue (labels blocked for bot token); autonomy granted via `approve-autonomous` in chat 2026-07-19 |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous e2e-ci-canary`

## Sanity check

**Result:** `proceed` — phases are scoped; workflow edits unblocked (#228); no prod migrations or auth route changes.

## Phases

### Phase 0 — Instrumentation

| Field | Value |
|-------|-------|
| **id** | `0` |
| **branch** | `cursor/e2e-canary-phase0-instrument-48ef` |
| **exit_checklist** | `governance` |

**Scope:** `summarize-playwright-retries.mjs`, `check-smoke-tags.mjs` skeleton, baseline retry note in `docs/ci-cd-baseline.md`. No workflow/gate changes.

**Exit:** Documented retry recovery; tag lint skeleton ready for Phase 1.

### Phase 1 — Smoke tags & Playwright projects

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/e2e-canary-phase1-tags-48ef` |
| **exit_checklist** | `governance` |

**Scope:** `@smoke-ci` / `@smoke-uat` tags, Playwright projects, npm scripts, axe split, README.

**Exit:** `npm run test:smoke-ci` green locally in &lt;2 min.

### Phase 2a — PR CI canary (advisory)

| Field | Value |
|-------|-------|
| **id** | `2a` |
| **branch** | `cursor/e2e-canary-phase2a-ci-advisory-48ef` |
| **exit_checklist** | `governance` |

**Scope:** `ci-e2e-canary` job (not in `ci-gate` yet), reusable workflow extension.

**Exit:** ≥3 consecutive green advisory runs.

### Phase 2b — PR CI canary (blocking)

| Field | Value |
|-------|-------|
| **id** | `2b` |
| **branch** | `cursor/e2e-canary-phase2b-ci-blocking-48ef` |
| **exit_checklist** | `governance` |

**Scope:** Add canary to `ci-gate` / `assert-ci-gate.sh` / `docs/ci-cd-gates.md`.

**Exit:** `ci-gate / CI passed` requires canary; soak ≥5 green advisory runs, &lt;5% pass-on-retry.

### Phase 3 — UAT live smoke hardening

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/e2e-canary-phase3-uat-smoke-48ef` |
| **exit_checklist** | `governance` |

**Scope:** `deploy-uat.yml` → `test:smoke-uat`, retries 0, weight/signup decisions, flake hardening.

**Exit:** Live smoke ≤5 min green; prod-ready gate list unchanged.

### Phase 4 — Full shard retry tuning

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/e2e-canary-phase4-shard-retries-48ef` |
| **exit_checklist** | `governance` |

**Scope:** `full` project retries 0, `fail-fast: true` on shard matrix, top flake spec hardening.

**Exit:** Cascade failures no longer double time on retries.

## Runtime state

```yaml
autonomy: active
current_phase: 2a
last_completed_phase: 1
halt_reason: null
next_action: "continue phase 2a on branch cursor/e2e-canary-phase2a-ci-advisory-8b4d"
artifact_ref:
  branch: cursor/e2e-canary-phase2a-ci-advisory-8b4d
  plan_path: .agents/plans/e2e-ci-canary.md
  plan_commit: pending
  snapshot_path: .agents/plans/e2e-ci-canary.snapshot.json
  snapshot_commit: pending
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/246"]
merge_commits: {"0":"dd82521a52bb51be8b5d0a177e4679d0a6229098","1":"8f4cce4"}
debt_issue_refs: []
```
