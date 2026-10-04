---
title: test-health-ci-verify-a8c2
owner: Agent
audience: agent
status: active
last_updated: 2026-10-04
tags: [execute-plan, test-health, verification]
---

# TEST programme verification — live signals & hardening

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `test-health-ci-verify-a8c2` |
| **title** | TEST programme verification (UAT smoke, weekly jobs, back-nav, phase-7 hardening) |
| **author** | Cloud agent (from user chat 2026-10-04) |
| **created** | 2026-10-04 |
| **base_branch** | `cursor/test-health-ci-verify-integration-edcb` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **parent programme** | `test-health-ci-5f3a` (delivered on `main`; this plan verifies and fixes signals) |

## Goal

`test-health-ci-5f3a` merged all seven phases, but **merged ≠ verified** for live UAT smoke, weekly KPI/ZAP/k6, and several phase-7 depth checks. This plan makes those signals **trustworthy once** (documented green runs), fixes broken weekly job setup before the first Monday cron, adds the missing People back-navigation journey test, hardens phase-7 tests in small PRs, and records an explicit human decision on the #1470 agent-memory change.

**Programme exit (control issue):** Close when integration has merged to `main` **and** each of these has at least one **trusted green** run recorded on the control issue:

1. UAT in-host smoke (`uat-live-e2e.yml` SSH leg)
2. `quality-kpis.yml`
3. `security-dast.yml` (setup + scan completes; findings advisory)
4. `perf-weekly.yml` (setup + k6 completes)

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-10-04T21:05:00Z |
| **approved_until** | 2026-10-06T21:05:00Z |
| **approved_by** | User chat 2026-10-04: write execute-plan with integration branch and autonomy throughout all phases without confirmation; scope = agreed verification order (UAT smoke, weekly jobs before Monday, back-nav test, phase-7 hardening PRs, #1470 memory decision, verification issue exit criteria). |
| **control_issue** | #1525 |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous test-health-ci-verify-a8c2`

## Integration workflow

- Integration parent: `cursor/test-health-ci-verify-integration-edcb` (from `main`).
- Phases 1–8: PR → integration (babysit+).
- Final: one PR integration → `main` (babysit-uat + pre-UAT gate).

## Phases

### Phase 1 — UAT in-host smoke fix

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/test-health-verify-uat-smoke-edcb` |
| **exit_checklist** | `governance` |

**Scope:**

- Diagnose latest failing `uat-live-e2e` / in-host SSH smoke from GitHub Actions logs (`gh run view` / job logs).
- Fix root cause (secrets, script on host, Node path, migrate status, etc.).
- If failure is **UAT DB/migrations**, move migrate/status gate into **deploy-uat** (or existing deploy smoke); narrow nightly in-host job to **app loopback checks only** (no duplicate migrate redesign).
- Document operator notes in `docs/e2e/uat-deploy-tiers.md` or runbook if behaviour changes.

**Exit criteria:**

- [ ] At least one **manual or post-merge** workflow run of the in-host leg reaches green, or deploy pipeline owns DB gate and in-host smoke green without migrate failure.
- [ ] Failure mode documented if infra secrets missing (fail closed with clear log line).

---

### Phase 2 — Weekly KPI / ZAP / k6 jobs operational

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/test-health-verify-weekly-jobs-edcb` |
| **exit_checklist** | `governance` |

**Scope:**

- Fix `perf-weekly.yml` k6 GPG key fingerprint if invalid.
- Use `e2e/scripts/bootstrap-db.sh` (same as PR CI) before `migrate.js up` in weekly workflows.
- Pin `runs-on: ubuntu-24.04` for PostgreSQL-dependent weekly jobs.
- Ensure artifacts upload (ZAP report, k6 summary).
- Split **setup** from **advisory scan**: setup steps must fail visibly; scan steps may remain `continue-on-error` with optional issue on failure (debt or workflow comment).
- `workflow_dispatch` run each of: `quality-kpis.yml`, `security-dast.yml`, `perf-weekly.yml` once; record run URLs on control issue.

**Exit criteria:**

- [ ] All three workflows complete setup successfully on `workflow_dispatch`.
- [ ] `docs/pipelines/ci-cd-gates.md` updated with owner/read expectation for weekly artifacts.

---

### Phase 3 — People back-navigation journey test

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/test-health-verify-back-nav-edcb` |
| **exit_checklist** | `bdd-journey` |

**Scope:**

- Add Playwright (and `@bdd` linkage where applicable) for People/Contacts **back navigation** journey — gap left after #1455 vet journey removal.
- Keep scope to one verifiable outcome: user navigates into People detail and returns to the hub/list.

**Exit criteria:**

- [ ] New spec runs in PR affected-E2E or canary path.
- [ ] BDD gate still passes (`check_bdd_coverage.js`).

---

### Phase 4 — `main.dart.js` bundle budget

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/test-health-verify-js-budget-edcb` |
| **exit_checklist** | `governance` |

**Scope:**

- Add per-file budget for `flutter_app/build/web/main.dart.js` (~5% headroom over current `main`).
- Wire check in `_reusable-build-web.yml` alongside total-web budget.

**Exit criteria:**

- [ ] `check-web-bundle-budget.mjs` (or sibling) fails on regression above `main.dart.js` ceiling.

---

### Phase 5 — Unauthenticated routes expect 401/403

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/test-health-verify-auth-matrix-edcb` |
| **exit_checklist** | `default` |

**Scope:**

- Tighten `unauthenticatedApiRouteMatrix.test.js`: protected routes must return **401 or 403** (not merely non-2xx).
- Maintain explicit **public route allowlist** (auth signup/login, org public, share preview, etc.).

**Exit criteria:**

- [ ] Jest green; no new public routes without allowlist entry.

---

### Phase 6 — IDOR probe expansion

| Field | Value |
|-------|-------|
| **id** | `6` |
| **branch** | `cursor/test-health-verify-idor-edcb` |
| **exit_checklist** | `default` |

**Scope:**

- Extend PG integration IDOR coverage for core resources: pets, health entries/issues, people, sharing (read/update/delete probes as appropriate).

**Exit criteria:**

- [ ] New tests run in `Backend integration (PostgreSQL)` CI job.

---

### Phase 7 — Schema equivalence isolated database

| Field | Value |
|-------|-------|
| **id** | `7` |
| **branch** | `cursor/test-health-verify-schema-db-edcb` |
| **exit_checklist** | `governance` |

**Scope:**

- Run `check-schema-equivalence` / integration wrapper in **isolated DB** or dedicated Jest project so `RESET_DB=true` does not disturb serial `test/db` siblings.

**Exit criteria:**

- [ ] Full server `test/db` suite order-independent green in CI.

---

### Phase 8 — Agent memory (#1470) governance

| Field | Value |
|-------|-------|
| **id** | `8` |
| **branch** | `cursor/test-health-verify-memory-gov-edcb` |
| **exit_checklist** | `governance` |

**Scope:**

- Post on control issue: diff summary of `.agents/memory/execute-plan-autonomy.md` (or related) from #1470.
- **Human gate:** wait for control-issue comment `keep-memory-1470` or `revert-memory-1470`.
- If `revert-memory-1470`: open PR reverting or narrowing the out-of-path memory change; if `keep-memory-1470`: document rationale in `docs/agent-efficiency/` (one paragraph) — no revert.

**Exit criteria:**

- [ ] Keyword recorded on control issue.
- [ ] Resulting doc or revert PR merged to integration.

---

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "start phase 1: checkout cursor/test-health-verify-uat-smoke-edcb"
artifact_ref:
  branch: cursor/test-health-ci-verify-integration-edcb
  plan_path: .agents/plans/test-health-ci-verify-a8c2.md
  plan_commit: dcc4763690ee8dc21a8d50ed3bd51862b7001ffb
  snapshot_path: .agents/plans/test-health-ci-verify-a8c2.snapshot.json
  snapshot_commit: dcc4763690ee8dc21a8d50ed3bd51862b7001ffb
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## References

- Prior plan: `test-health-ci-5f3a` (closed #1449)
- User verification bar: UAT smoke + KPI + ZAP + k6 each one trusted green
