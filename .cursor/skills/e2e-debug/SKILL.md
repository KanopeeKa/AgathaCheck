---
name: e2e-debug
description: >-
  Pre-UAT E2E remedial workflow — diff since last green pre-UAT run, union failed
  and at-risk shards, parallel shard workers on one remedial branch, local isolated
  shard replay. Use when pre-UAT is red, proactively before CI finishes on high-risk
  merges, or when /babysit-uat or /execute-plan delegates remedial work.
paths:
  - e2e/**
  - scripts/babysit_uat*.sh
  - scripts/babysit_uat*.mjs
  - scripts/e2e_debug*.mjs
  - scripts/e2e_debug_status.mjs
---

# E2E debug

Pre-UAT **remedial fix loop** — triage CI, scope shards from **diff since last green** `pre-uat-e2e.yml`, fix on **one remedial branch**, validate locally, open remedial PR. **Does not merge** — hand off to **/babysit-uat** for merge + watch.

**Canonical scripts:** `scripts/e2e_debug_status.mjs` (preflight) · `scripts/e2e_debug_resolve.mjs` · `scripts/babysit_uat_shard_risk.mjs`  
**Memory:** `.agents/memory/uat-live-e2e-triage.md` · `docs/e2e/uat-deploy-tiers.md`

---

## Router (e2e-debug)

**Profile:** `classify-first` — see `protocols/e2e.md`.

1. Run Phase 0 preflight below **first** (unchanged).
2. Classify failure: `PRODUCT BUG` · `TEST BUG` · `TEST DATA` · `ENVIRONMENT` · `RACE` · `SELECTOR FRAGILITY` · `INFRASTRUCTURE` · `UNKNOWN`.
3. **No test changes** before reasoned classification.
4. Load other protocols only if root cause requires (e.g. 403 → `authorization`, `api-contract`).

---

## Phase 0 — Preflight (mandatory — before anything else)

**Do not** bootstrap the stack, spawn shard workers, or create a remedial branch until preflight passes.

```bash
node scripts/e2e_debug_status.mjs --json
```

| Exit / `safe_to_start` | Action |
|------------------------|--------|
| `0` / `true` | Proceed to Phase 1 |
| `2` / `false`, `reason: e2e_debug_in_progress` | **Stop** — another agent holds `e2e-debug` + `busy` on a control issue. Wait, or comment on that issue and coordinate |
| `2` / `false`, `reason: open_remedial_pr` | **Join** the open remedial PR — do not start a duplicate branch/stack. Re-run with `--join --remedial-branch <branch>` after resolve |
| `2` / `false`, `reason: open_e2e_pr_while_main_red` | **Join** the open E2E PR while `main` pre-UAT is red — same join flow; do not open another `e2e/**` PR |
| `2` / `false`, `reason: join_branch_mismatch` | Use `open_remedial_pr.branch` from JSON — one remedial PR per failure wave |

**Claim session** (when starting fresh — control issue from `/execute-plan` or babysit-uat context):

```bash
node scripts/e2e_debug_status.mjs --claim --issue <control_issue> --merge-sha <merge_sha> --json
```

Adds `e2e-debug` + `busy` on the issue so parallel agents do not duplicate orchestration. Claim re-checks preflight, provisions the `e2e-debug` label, adds both labels in one edit, and rolls back on race detection.

**Join existing remedial PR** (after resolve returns `remedial_branch`):

```bash
node scripts/e2e_debug_status.mjs --join --remedial-branch <remedial_branch> --json
git fetch origin <remedial_branch>
git checkout <remedial_branch>
```

**Release** when remedial PR is ready for `/babysit-uat` handoff (or session halts):

```bash
node scripts/e2e_debug_status.mjs --release --issue <control_issue> --json
```

`--force` bypasses the busy guard (ops recovery only — document why in the issue comment).

---

## When to use

| Caller | Mode |
|--------|------|
| Pre-UAT failed (`babysit_uat_watch_preuat.sh` exit 1) | **Reactive** — `--merge-sha` |
| `/babysit-uat` Phase 2 `act_now` or Phase 3 | **Proactive** or **reactive** |
| `/execute-plan` final merge pre-UAT red | **Reactive** — same remedial branch |
| Manual `/e2e-debug` on red main | **Reactive** |
| High-risk merge landed; CI still running | **Proactive** — `--proactive` |

---

## Inputs

| Input | Required | Notes |
|-------|----------|-------|
| `merge_sha` | reactive | Failing merge commit on `main` |
| `failed_shards` | optional | From watch JSON; resolve also reads CI |
| `plan_id` | when in execute-plan | Control-issue comment |
| `remedial_branch` | optional | Default from resolve JSON |
| `round` | optional | `2+` = failed shards only (no proactive expansion) |

---

## Model

**`composer-2.5` only** for orchestrator and **all** shard Task subagents (audit, fix, isolated replay). No thinking/high models for remedial orchestration.

---

## Phase 1 — Resolve scope

```bash
git fetch origin main

# Reactive (pre-UAT failed for this merge):
node scripts/e2e_debug_resolve.mjs --merge-sha <merge_sha> --json

# Proactive (high-risk on main, CI still running):
node scripts/e2e_debug_resolve.mjs --proactive --json

# Round 2+ (only CI-reported failures — pass explicit baseline if needed):
node scripts/e2e_debug_resolve.mjs --merge-sha <merge_sha> --json
# Then restrict target_shards to failed_shards only
```

**Union rule:** `target_shards = failed_shards ∪ { medium/high risk from diff since baseline }`. Include **low** risk only when `e2e/playwright/support/` changed. Pre-UAT matrix uses **fail-fast** — CI `failed_shards` is often incomplete.

Record: `baseline_sha`, `target_shards`, `remedial_branch`, `parallel_workers`.

---

## Phase 2 — CI triage (reactive)

When `failing_run_id` present:

```bash
gh run view <failing_run_id> --log-failed
gh run download <failing_run_id> -D /tmp/preuat-artifacts
```

Read `test-results/**/error-context.md`, traces, shard job logs. Map shard → specs:

```bash
node e2e/scripts/shard-files.mjs <shard_index>
```

---

## Phase 3 — Remedial branch

```bash
git checkout -b <remedial_branch> origin/main
# default: cursor/preuat-fix-<head8>-6bba from resolve JSON
```

**One remedial PR** for all shard fixes — no stacked pre-UAT patches.

---

## Phase 4 — Ownership (parallel workers)

Publish before spawning workers:

| Worker | Owns | Never touch |
|--------|------|-------------|
| **orchestrator** | `e2e/playwright/support/*`, shared helpers | — |
| **shard-N** | specs in shard N (`node e2e/scripts/shard-files.mjs N`) + their `pages/*` | other shards' specs, `support/*` |

**Never parallelize** the same spec file or page object across workers.

---

## Phase 5 — Parallel workers (`parallel_workers: true`)

Spawn **Task subagents** (`generalPurpose`, **`composer-2.5`**) — one per target shard:

| Subagent task | Allowed |
|---------------|---------|
| Static audit (grep locators, semantics drift) | Yes — parallel |
| Code fixes on disjoint owned files | Yes — parallel |
| Playwright on **same Cloud pod** | **No** — port/DB races |

**Playwright validation:**

| Environment | Command |
|-------------|---------|
| **Separate Cloud Agent pod** per shard (preferred for parallel) | `./scripts/babysit_uat_bootstrap_stack.sh` then `./scripts/babysit_uat_run_shard_isolated.sh <N>` |
| **Single orchestrator pod** | Sequential `./scripts/babysit_uat_run_shard.sh <N>` after workers push fixes |

Workers push to **same remedial branch**; orchestrator rebases between pushes when specs overlap.

**Single shard:** orchestrator fixes + validates locally — no subagents required.

---

## Phase 6 — Local stack (once per pod)

```bash
./scripts/babysit_uat_bootstrap_stack.sh
cd e2e && npx playwright install chromium --with-deps   # fresh pods
# Confirm flutter_app/build/web/main.dart.js is complete before UI tests
```

Validate each `target_shard` (high → low risk):

```bash
./scripts/babysit_uat_run_shard.sh <shard>
# or isolated (parallel pods): ./scripts/babysit_uat_run_shard_isolated.sh <shard>
```

---

## Phase 7 — Verify + PR

```bash
./scripts/pre-push-changed.sh
./scripts/pre-push-changed.sh --e2e-shards <comma-separated target_shards>
```

Open/update remedial PR to `main`. PR body: baseline SHA, target shards, failing run URL, drift checklist hits.

**Release** the preflight claim when handing off (not when stopping):

```bash
node scripts/e2e_debug_status.mjs --release --issue <control_issue> --json
```

---

## Phase 8 — Mandatory handoff (same session — do not skip)

`/e2e-debug` is **incomplete** until **`/babysit-uat` runs on the remedial PR in the same agent session** (or an explicit queued follow-up that will run it immediately).

| Step | Action |
|------|--------|
| 1 | Mark remedial PR **ready for review** (`gh pr ready` or `ManagePullRequest update_pr` with `draft: false`) |
| 2 | Post handoff comment: failing `merge_sha`, target shards, CI run URL, local shard evidence |
| 3 | Release `e2e-debug` claim when one was taken (`--release`) |
| 4 | **Immediately invoke `/babysit-uat`** on the remedial PR — merge + `babysit_uat_watch_preuat.sh` |

**Do not** end the turn after opening a draft remedial PR. Saying "hand off to `/babysit-uat`" without running it leaves `main` red.

| Anti-pattern | Result |
|--------------|--------|
| Open draft remedial PR and stop | Pre-UAT stays broken; no merge |
| Standalone `/e2e-debug` with no follow-up | Process failure — always chain `/babysit-uat` |
| Release claim before babysit-uat starts | OK only when babysit-uat is already running in same session |

**Hand off to /babysit-uat** (Phase 4 remedial loop):

- `/babysit-plus` merge remedial PR
- `./scripts/babysit_uat_watch_preuat.sh <new_merge_sha>`

Do **not** poll promote/deploy.

---

## Drift checklist (common fixes)

| Symptom | Check |
|---------|-------|
| `Pet: Max` timeout | Dashboard card label changed — `pet-list.page.ts` |
| `Welcome to Agatha Track` on wrong route | FTUE vs `/g/onboarding` — `flutter.ts` |
| Section heading not found | Semantics **group** not text — `semanticsByName` |
| `flutter-view` timeout | Incomplete web build or server down |
| `Executable doesn't exist` | `npx playwright install chromium` |
| Post-login wrong shell | `/g/home` vs `/g/pets` route drift |

Full symptom map: `.agents/memory/uat-live-e2e-triage.md`

---

## Round 2+ (remedial failed again)

1. `node scripts/e2e_debug_status.mjs --join --remedial-branch <branch> --json` (or fresh preflight if branch changed)
2. `node scripts/e2e_debug_resolve.mjs --merge-sha <remedial_merge_sha> --json`
3. **Only** fix `failed_shards` from watch — no proactive expansion
4. Same remedial branch or new `cursor/preuat-fix-<sha>-6bba` from current `origin/main`
5. Max **3** full loops per original feature PR (inherits `/babysit-uat` budget)

---

## Avoid wasting time

| Do first (cheap) | Defer (expensive) |
|------------------|-------------------|
| Phase 0 preflight | Bootstrap stack + Playwright install |
| `e2e_debug_resolve.mjs` + CI log triage | Local shard replay |
| Static grep/locator audit per shard | Full isolated pod per shard |
| `--join` existing remedial PR | New remedial branch + duplicate PR |

| Rule | Why |
|------|-----|
| **Preflight before bootstrap** | Stack + `playwright install` is minutes; duplicate agents race on the same remedial branch |
| **Join, don't fork** | One remedial PR per failure wave — open PR without `--join` means continue that branch |
| **Proactive only when `merge_action == act_now`** | Round 1 high-risk only; round 2+ waits for CI `failed_shards` |
| **Static audit before Playwright** | Grep locators/semantics drift in parallel; run shards only when audit finds drift or CI proved failure |
| **Sequential Playwright on one pod** | Never parallel `babysit_uat_run_shard.sh` on the same pod — port/DB races |
| **Isolated pods for parallel replay** | `babysit_uat_run_shard_isolated.sh` only when separate Cloud Agent pods |
| **`--e2e-shards` not full suite** | `./scripts/pre-push-changed.sh --e2e-shards <target_shards>` after fixes |
| **Subscribe to CI, don't poll** | Use `cursor-subscriptions` `subscribe_github_ci` on `pre-uat-e2e.yml` while fixing |
| **Release `busy` on handoff** | Unblocks the next remedial round if babysit-uat must re-delegate |

---

## Related

| Skill | When |
|-------|------|
| `/babysit-uat` | Merge remedial PR + pre-UAT watch — **after** this skill |
| `/pre-push-verify` | `--e2e-shards` after fixes |
| `/spawn-sprint-agents` | Ownership pattern only — **no** integration branch for remedial |
| `/execute-plan` | Delegates here on pre-UAT failure before `complete-plan` |
| `/add-bdd-playwright-scenario` | Adding coverage — not remedial |
