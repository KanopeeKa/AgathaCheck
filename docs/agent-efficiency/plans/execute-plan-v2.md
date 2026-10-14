---
title: Execute-plan v2 — build spec (merged + deployed to UAT)
owner: Kanopee
audience: agent
status: active
last_updated: 2026-10-15
tags: [agent, execute-plan, autonomy, uat]
---
# Execute-plan v2 — build spec

Self-contained build specification. The executor (Claude Code on Sonnet, one session per work
package) has **no access** to the conversation that produced it. Everything needed is in this
folder. Facts are cited as `path:line` on `main` @ `6fa8236` or as live GitHub reads on 2026-10-15.
Anything not verified is marked **VERIFY:** with the command that checks it.

| Part | File | Read when |
|------|------|-----------|
| Index (this file) | `execute-plan-v2.md` | Always first |
| Data contracts + state machine | [`execute-plan-v2/contracts.md`](./execute-plan-v2/contracts.md) | Every WP |
| Runtime work packages WP1–WP5 | [`execute-plan-v2/work-packages-runtime.md`](./execute-plan-v2/work-packages-runtime.md) | WP1–WP5 |
| Platform work packages WP6–WP8 + workflow YAML | [`execute-plan-v2/work-packages-platform.md`](./execute-plan-v2/work-packages-platform.md) | WP6–WP8 |
| Owner runbooks, proof run, retirement | [`execute-plan-v2/runbooks-proof-retirement.md`](./execute-plan-v2/runbooks-proof-retirement.md) | Phase 0, WP8–WP10 |

## Disagreements with Opus (kept visible, with evidence)

1. **One file → one folder.** `scripts/check_file_size.js:30` enforces 500 lines per hand-written
   file and each work package is consumed by a separate session, so the spec is split per topic.
   The index lives at the path Opus named.
2. **Identity default = machine user with a classic PAT (`repo` scope, no `workflow`).** The repo
   owner is a personal account (`owner.type = User`, live read), and fine-grained PATs can only
   target resources owned by the token holder or an organisation, so the "fine-grained" path is
   not available here. A GitHub App is offered for the driver only. Both are in the runbook.
3. **Keep `agent-pr-safety-gate.yml` untouched during the build.** The scope check imports
   `FORBIDDEN_PATH_PATTERNS` from `.github/scripts/agent-safety-lib.js` instead of copying it;
   folding the two gates is a retirement item so the live gate for non-plan PRs is never at risk.
4. **Sync uses a PR, not the merges API.** The integration ruleset requires PRs, so a direct merge
   from the driver would be rejected. The driver opens `main → integration` sync PRs merged with a
   **merge commit** (never squash — a squash would make the release PR's changed-file list include
   `main`'s own changes and turn the scope check red). Repo allows merge commits (live read).
5. **Claude Code `Stop` hook is included but last and optional.** It is the only piece that depends
   on platform behaviour; no acceptance criterion depends on it.

Everything else in Opus's review (B1–B9, R1–R13) is adopted as written.

## 1. Goal, Definition of Done, non-goals, glossary

**Goal.** `/execute-plan` starts pre-planned, pre-approved work and runs it to the end without
owner messages: phases land on an integration branch, one release PR lands on `main`, and the
result is live on UAT. A turn ending, a red CI run, a cancelled Pre-UAT run or a moving `main`
cost minutes, never the programme. The owner intervenes only on a fixed list of STOP reasons.

**Definition of Done (observable on GitHub, computed by `tick`, never declared by an agent):**
1. The release PR (head = integration branch, base = `main`) is merged → `merge_sha`.
2. A **Pre-UAT E2E** run on `main` concluded `success` whose `head_sha` contains `merge_sha`
   (compare API status `ahead` or `identical`).
3. A `uat-*` tag exists whose commit contains `merge_sha`.
4. A **Deploy UAT** run concluded `success` for a head that contains `merge_sha` and was created
   after the release merge.

Tier 3 (`UAT Live E2E`) is recorded as advisory unless `settings.tier3_blocking` is true.

**Non-goals.** Production deploys; changing the UAT pipeline itself; multi-repo plans; parallel
phases; replacing babysit+ for non-plan PRs; any new prose rule about "not stopping".

**Glossary.** *Plan* — `.agents/plans/<id>.md` (human scope) + `<id>.snapshot.json` (machine
scope), both immutable after approval. *Control issue* — the GitHub issue holding approval,
labels and the status comment. *Integration branch* — `cursor/<id>-integration-<suffix>`.
*Phase PR* — phase branch → integration. *Release PR* — integration → `main`. *Remedial PR* —
`cursor/<id>-remedial-N` → `main`, only during the UAT stage. *Sync PR* — `main` → integration.
*Driver* — the GitHub Actions workflow that runs `tick` on events. *Worker* — a launched Cursor
agent (or Claude Code session) executing one `agent` action. *Lease* — the record proving a worker
is alive. *Owner* — a login listed in `.github/execute-plan.config.json` on `main`.

## 2. Executor ground rules

**Work packages and branches**
- One work package per session and per PR, branched from `main`. Use the session's designated
  branch unless the kickoff prompt explicitly allows `claude/execute-plan-v2-wp<N>`.
- Each WP in the parts files carries a 3–5 line kickoff prompt; the owner pastes it into a new
  session (model: Sonnet).
- Never merge a PR that touches `.github/**`; mark it ready and hand off. Never apply rulesets.

**Repo conventions**
- `./scripts/pre-push-changed.sh` before every push; `./scripts/pre-push.sh` before marking ready.
- PR body contains a `## Docs` section (docs gate).
- Files ≤ 500 lines (`node scripts/check_file_size.js`); new modules are split before they get near it.
- Node 22; tests with `node:test`; runtime tests run via `node --test scripts/execute_plan_runtime.test.js`
  from `scripts/pre-push-changed.sh:135`. New test files are added to that line.
- Docs frontmatter: `title`, `owner`, `audience`, `status`, `last_updated`, `tags` within the first
  10 lines (`scripts/validate_docs.sh:64`).

**GitHub access in code**
- All GitHub I/O goes through `scripts/lib/execute_plan_github.js` (global `fetch`, token from
  `EXECUTE_PLAN_TOKEN`, then `GH_TOKEN`, then `GITHUB_TOKEN`). **No `gh` in new code.** The
  existing `scripts/lib/execute_plan_project.js` keeps its `gh` calls until retirement.
- Tests are offline: every client call is replayed from JSON fixtures under
  `scripts/test/fixtures/execute-plan-v2/`. A test that performs a live call is a defect.

**Hand-offs**
- Stop at the marked owner hand-off points. If a **VERIFY** fails, stop and report the command and
  its output; never improvise around it.
- v1 (`schema_version` absent or `1`) keeps working until the retirement PR (B8).

## Phase 0 — decisions (defaults apply unless the owner changes them)

| Decision | Default | Where it lands |
|----------|---------|----------------|
| Identity | Machine user `agatha-bot` (name is a placeholder; owner picks), classic PAT `repo` scope, **no** `workflow`; stored as secret `EXECUTE_PLAN_BOT_TOKEN` and as the Cursor cloud secret `GH_TOKEN` | Runbook §7.1 |
| Owner logins | `["KanopeeKa"]` | `.github/execute-plan.config.json` on `main` |
| Window | default 7 days, hard cap 14 | `execute_plan_constants.js` (v2 block) |
| CI attempts per phase / release | 3 | snapshot `settings.budgets.ci_per_phase` |
| Launches per phase | 3 | `settings.budgets.launches_per_phase` |
| Remedial rounds | 3 | `settings.budgets.remedial_rounds` |
| Sync attempts | 2 | `settings.budgets.sync_attempts` |
| Daily launch cap per plan | 10 | `settings.budgets.daily_launches` |
| Tier 3 live E2E | advisory | `settings.tier3_blocking: false` |
| Release owner review | off | `settings.release_owner_review: false` |
| Worker platform | Cursor launches (API); Claude Code only through the Stop hook | WP7, WP6 |
| `main` ruleset | add required check `execute-plan-scope`; keep `strict` (driver runs `update-branch`); keep reviews = 0 | Runbook §7.2 |
| Repo setting | enable **Allow auto-merge** (currently `false`, live read) | Runbook §7.3 |
| Kill switch | repo variable `EXECUTE_PLAN_DRIVER` = `dry-run` until the proof run, then `on` | Runbook §7.4 |

A plan may lower any budget; it may never raise one above the cap in code (R12).

## Order and hand-off points

```
Phase 0 decisions (owner, 10 min)
  → §7.1 identity + secrets (owner)                         ← prerequisite for the driver (B1)
  → WP1 GitHub client + fixtures
  → WP2 scope matcher + check-diff
  → WP3 snapshot v2 + init + approval hash
  → WP4 tick: phases, sync, release
  → WP5 tick: UAT stage, watchers, complete-plan verification
  → WP6 skills + rules (Cursor + Claude Code)
  → WP7 workflow scripts + three workflows (owner merges; driver starts in dry-run)
  → WP8 scope check wiring + rulesets (owner applies §7.2, §7.3)
  → WP9 proof run (first v2 plan)                            ← gate for trusting v2
  → WP10 retirement PR
```

Owner hand-offs: after Phase 0; after WP7 (merge workflows, set variables); after WP8 (rulesets,
auto-merge, `EXECUTE_PLAN_DRIVER=on`); approval comment of the proof run; after WP9 (go / no-go).

## Live GitHub facts the design relies on (read 2026-10-15)

- `main` is governed by ruleset **"Main protection"** (active): `non_fast_forward`;
  `required_status_checks` = `Analyze JavaScript`, `ci-gate / CI passed`, **strict = true**;
  `pull_request` with 0 required reviews; `copilot_code_review`. Classic branch protection is not
  used (`/branches/main/protection` → 404). **VERIFY:** whether the `pull_request` rule also sets
  `required_review_thread_resolution`: `gh api repos/KanopeeKa/AgathaCheck/rules/branches/main --jq '.[] | select(.type=="pull_request") | .parameters'`.
- Tag rulesets **"UAT tag"** and **"PROD tag"** are active; `promote-uat.yml` tags with a PAT.
- Repo: public, `allow_auto_merge = false`, `allow_squash_merge = true`,
  `allow_merge_commit = true`, `delete_branch_on_merge = true`.
- `ci.yml:10-13` runs the PR tier on PRs into `main`, `cursor/*-integration-*`, `claude/**`.
- `pre-uat-e2e.yml` triggers on `push: main` and `workflow_dispatch`, concurrency
  `cancel-in-progress: true`; `promote-uat.yml` tags only when `origin/main` HEAD equals the tested
  SHA; `deploy-uat.yml` runs on `uat-*` tag push, on `workflow_run` of
  `Promote UAT (tag on merge to main)`, and on `workflow_dispatch(deploy_ref)`.
- Reliability, last 30 runs: Pre-UAT 24 green / 4 red / 2 cancelled; Promote 6 throttle skips;
  Deploy 29 / 1. Red and cancelled runs are normal operating conditions, not edge cases.

## 10. Risks, residuals, rollback

| Risk | Mitigation | Rollback |
|------|-----------|----------|
| Driver launches in a loop | per-plan `concurrency` group, lease, launch budgets, daily cap, kill switch | `EXECUTE_PLAN_DRIVER=off` (immediate, no deploy) |
| Scope check blocks unrelated PRs | passes any PR that is not a plan category; fixture PR before the ruleset change | owner removes `execute-plan-scope` from the ruleset |
| Auto-merge lands a revoked plan | scope check fails on revoke/expiry/STOP (B3); driver disables auto-merge on STOP | `revoke-autonomous <id>` comment or label |
| Bot token leaks | `repo` scope only, no `workflow`, no admin; secrets never passed to `pull_request_target` jobs | rotate PAT; revoke collaborator |
| Pre-UAT red for reasons outside the plan | baseline comparison → `awaiting-main-green`, bounded 6 h → STOP `main-red` | none needed |
| Deploy failure misclassified | fixed class table from `deploy-uat.yml` step ids; unknown → STOP `uat-unknown`, never remedial | manual `deploy-uat` dispatch per `docs/e2e/uat-promote-manual.md` |
| v1 plans break during the build | v1 code paths untouched until WP10 | revert WP10 |
| Cursor API shape changes | one `launchPlanAgent` function with a recorded request fixture | driver `dry-run` |

Each WP is one PR and reverts independently; order of safe reversal is WP10 → WP8 → WP7 → WP6 → WP5 → WP4 → WP3 → WP2 → WP1.
