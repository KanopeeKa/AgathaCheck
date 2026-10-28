---
title: Execute-plan v2 — build spec (merged + deployed to UAT)
owner: Kanopee
audience: agent
status: active
last_updated: 2026-10-28
tags: [agent, execute-plan, autonomy, uat]
---
# Execute-plan v2 — build spec

Self-contained build specification. Executors (Cursor Cloud Agents on the model named by the Cloud Agent model policy, or Claude Code
sessions — one session per work package) have **no access** to the conversation that produced it.
Facts are cited as `path:line` on `main` @ `6fa8236` or as live GitHub reads on 2026-10-15.
Anything still unverified is a **VERIFY** with a decision for each outcome.

| Part | File | Read when |
|------|------|-----------|
| Index (this file) | `execute-plan-v2.md` | Always first (§2 ground rules) |
| Data contracts | [`execute-plan-v2/contracts.md`](./execute-plan-v2/contracts.md) | Every WP |
| Observations, decision rules, scenarios | [`execute-plan-v2/state-machine.md`](./execute-plan-v2/state-machine.md) | WP4a, WP4b, WP5, WP6a |
| WP1–WP3 (client, scope matcher, approval/init) | [`execute-plan-v2/work-packages-runtime.md`](./execute-plan-v2/work-packages-runtime.md) | WP1–WP3 |
| WP4a–WP5 (decide, tick, UAT) | [`execute-plan-v2/work-packages-tick.md`](./execute-plan-v2/work-packages-tick.md) | WP4a–WP5 |
| WP6a–WP8 (skills, workflows, rulesets) | [`execute-plan-v2/work-packages-platform.md`](./execute-plan-v2/work-packages-platform.md) | WP6a–WP8 |
| Owner runbooks, proof run, retirement | [`execute-plan-v2/runbooks-proof-retirement.md`](./execute-plan-v2/runbooks-proof-retirement.md) | Phase 0, WP8–WP10 |
| Work split and kickoff prompts | [`execute-plan-v2/work-split-and-prompts.md`](./execute-plan-v2/work-split-and-prompts.md) | Owner, before each WP |

## Review history

**Round 3 (owner Phase 0 decisions, 2026-10-15):** launches per phase 5 (cap 6); daily launches 20
(cap 30) and the daily cap waits instead of stopping; bot account `pawpet-bot` created with the repo
secret; **Cursor Cloud identity** (runbooks §7.1, post-#1941/#1952): dashboard **`GH_TOKEN`** =
`pawpet-bot` classic PAT by default; **`OWNER_GH_TOKEN`** + **`/runasme`** for owner-only GitHub
API actions; the driver passes the bot token to plan workers at launch (`envVars` from
**`EXECUTE_PLAN_BOT_TOKEN`**); git pushes and Cursor-opened PRs use the Cursor GitHub App regardless
of `GH_TOKEN`. Runbook §7.1 corrected for personal-account repos (no collaborator role picker). All other Phase 0
defaults confirmed.

**Round 1 (Fable, accepted by Opus):** the spec is split into a folder (500-line limit, one
session per WP); identity default = machine user with a classic PAT (`owner.type = User`, so
fine-grained PATs are not available); `agent-pr-safety-gate.yml` stays untouched until WP10;
sync uses a merge-commit PR (the integration ruleset requires PRs); the Claude Code `Stop` hook
is optional; the driver uses one global concurrency group in v1.

**Round 2 (Opus review on PR #1898, applied here):**

| # | Change | Where |
|---|--------|-------|
| 1 | Required checks pinned to GitHub Actions (`integration_id: 15368`); forged-status fixture | runbooks §7.2, WP8 (f) |
| 2 | Definition of Done #4 uses the `Prod ready` job + the deployed tag, so no-op deploy runs never count | §1, state-machine §4.0/U5, WP5 |
| 3 | `drift` = plan files whose bytes differ from the approved content; the release PR may carry them | WP2 rule 3a, WP7a |
| 4 | Snapshot always read at the immutable `init_sha` | contracts §3.5, WP4b, WP7a |
| 5 | Scope result = API check run (unforgeable by a PAT); `enforce-stop` turns it red on open PRs | contracts §3.7, WP7a, WP7b |
| 6 | Driver wakes on `workflow_run` of `CI` (not `check_suite`); heartbeat covers chain-depth limits | WP7b |
| 7 | v2 tests run in CI (governance job) | WP7a |
| 8 | `resume-autonomous` (same hash) renews time and budgets after a STOP | contracts §3.3, state-machine §4.1, runbooks §7.5 |
| 9 | `require_extra_approval_for_unattributed_changes` checked live before relying on auto-merge | WP8 step 2, runbooks §7.2 |
| 10 | Only the driver reads Cursor run status; workers report `UNKNOWN` | state-machine L2, WP4b, WP7b |
| 11 | Driver creates phase branches; launch fields copied from `launch-cursor-agent.js` | state-machine P2, WP7c |
| 12 | `rerun-ci` dropped | contracts §3.7 |
| 13 | One identity (bot token) for every control-issue write | contracts §3.5, token table |
| 14 | Proof run uses the real route `server/bin/server.js:158` | contracts §3.1, runbooks §8 |
| 15 | Executor rules and prompts written for Cursor first, Claude Code second | §2, work-split-and-prompts |
| 16 | `Observations` / `PrObs` / `UatObservations` defined | state-machine §4.0 |
| 17–18 | Hand-written scenario tests; no recorded traffic, no owner-run recorder | state-machine §4.5 |
| 19 | WP4 → 4a/4b, WP7 → 7a/7b/7c, WP6 → 6a/6b | parts files |
| 20 | Node built-ins only; JSON scope block instead of YAML | contracts §3.2, runtime rules |
| 21 | Required checks and UAT job names in the config file | contracts §3.8 |
| 22 | Every VERIFY has decisions; every WP has a "Do not touch" list | parts files |
| 23 | Inconsistencies fixed (`release_branch`, attempts = distinct failing SHAs, valid JSON, protected set) | contracts, state-machine |

## 1. Goal, Definition of Done, non-goals, glossary

**Goal.** `/execute-plan` starts pre-planned, owner-approved work and runs it to the end without
owner messages: phases land on an integration branch, one release PR lands on `main`, and the
result is live on UAT. A turn ending, a red CI run, a cancelled Pre-UAT run or a moving `main`
cost minutes, never the programme. The owner intervenes only on the fixed STOP list
(state-machine §4.3), and resumes with one comment.

**Definition of Done (observed on GitHub by `verifyComplete`, never declared by an agent):**
1. The release PR (head = integration branch, base = `main`) is merged → `merge_sha` (a later
   remedial PR's merge replaces it).
2. A **Pre-UAT E2E** run on `main` concluded `success` and its `head_sha` contains `merge_sha`
   (`compare(merge_sha...head_sha).status ∈ {ahead, identical}`).
3. A `uat-*` tag exists whose commit contains `merge_sha`.
4. A **Deploy UAT** run created after the merge has its `Prod ready` job concluded `success`
   (not `skipped`) and deployed (`DEPLOY_REF` in that job's log) a tag whose commit contains `merge_sha`.

Tier 3 (`UAT Live E2E`) is recorded as advisory unless `settings.tier3_blocking` is true.

**Non-goals.** Production deploys; changing the UAT pipeline; multi-repo plans; parallel phases;
replacing babysit+ for non-plan PRs; any new prose rule about "not stopping".

**Glossary.** *Plan* — `.agents/plans/<id>.md` + `<id>.snapshot.json`, immutable after approval.
*Control issue* — the issue holding approval comments, labels and the status comment.
*Integration branch* — `cursor/<id>-integration-<suffix>`. *Phase PR* — `cursor/<id>-p<n>` →
integration. *Sync PR* — `main` → integration. *Release PR* — integration → `main`. *Remedial PR*
— `cursor/<id>-remedial-<n>` → `main`, UAT stage only. *`init_sha`* — the commit with the approved
plan files. *Epoch* — time of the latest valid approve/resume comment. *Driver* — the Actions
workflow that runs `tick` and executes driver actions. *Worker* — a launched Cursor agent doing
one agent action. *Lease* — the record of the live worker. *Owner* — a login in
`.github/execute-plan.config.json` → `owners`.

## 2. Executor ground rules

**Not an execute-plan run.** Building v2 is ordinary PR work into `main`. Executors do not use
`/execute-plan`, `/babysit-plus` or `/babysit-uat`, and ignore the execute-plan stop rules in
`AGENTS.md` for this build.

**Branches and PRs**
- One work package per agent session and per PR, branched from `main`.
- Cursor: branch `cursor/execute-plan-v2-wp<N>-<4 lowercase letters or digits>`. Claude Code: the
  session's assigned branch.
- Plan first: open a draft PR whose body is a checklist of the WP's files, exports, tests and
  acceptance commands, plus `## Docs`. Mark it ready when everything is ticked and green.
- Never merge. The owner merges every WP PR (and reads every `.github/**` diff).

**Repo conventions**
- `./scripts/pre-push-changed.sh` before every push; `./scripts/pre-push.sh` before marking ready
  **when the environment can run it**. In agent cloud containers its database-backed server suites
  (`server/test/db`, which need the full local schema) and Flutter stages usually cannot run. Then:
  run `./scripts/pre-push-changed.sh`, the WP acceptance commands, and `cd server && npm run test:unit`
  when `server/` is touched; list in the PR body what could not run and why; **CI on the PR is the
  gate** for marking ready. Spend at most one attempt on database setup, never more.
- Known container fixes (environment only, never committed): `git config --global --add
  safe.directory '*'` when the Flutter SDK refuses to run; `BOT=true` when Flutter's root warning
  breaks the version check; `cd server && npm ci` before `validate_docs.sh` (it needs `js-yaml`);
  install `shellcheck` if pre-push asks for it. Discard a regenerated `docs/quality/scorecard.md`
  unless the WP lists it.
- Files ≤ 500 lines (`node scripts/check_file_size.js`); new modules ≤ 400 lines.
- Node 22, CommonJS, `node:test`; built-ins only in v2 code (it also runs in Actions without `npm ci`).
- New test files go under `scripts/test/` and into the governance block of
  `scripts/pre-push-changed.sh` (next to line 135); CI runs them after WP7a.
- Docs frontmatter within the first 10 lines (`scripts/validate_docs.sh:63-64`).

**GitHub access in code:** only through `scripts/lib/execute_plan_github.js` (WP1). No `gh` in new
code. Tests are offline: fake fetch for HTTP, plain objects and scenario files for logic.

**When something does not match:** each VERIFY lists decisions. If the outcome matches none, stop,
comment on the draft PR with the command and its output, and end the session.

## Phase 0 — decisions (defaults apply unless the owner changes them)

| Decision | Default | Where it lands |
|----------|---------|----------------|
| Identity | Machine user **`pawpet-bot`** (created; collaborator with write), classic PAT `repo` scope, **no** `workflow`; repo secret **`EXECUTE_PLAN_BOT_TOKEN`** (set); Cursor dashboard **`GH_TOKEN`** = bot PAT (default Cloud Agents); **`OWNER_GH_TOKEN`** + **`/runasme`** for owner API actions; plan workers get the bot token from the driver at launch (`envVars`); optional legacy alias **`BOT_GH_TOKEN`** — prefer **`GH_TOKEN`** | runbooks §7.1 |
| Owners | `["KanopeeKa"]` | config `owners` |
| Window | default 7 days, cap 14 | `V2_DEFAULTS` / `V2_CAPS` |
| Budgets | CI attempts 3 per PR, launches **5** per phase (cap 6), remedial 3, sync resolves 2, daily launches **20** per plan (cap 30) — reaching the daily cap **waits** until the next UTC day, it never stops the plan | snapshot `settings.budgets` (≤ caps) |
| Tier 3 live E2E | advisory | `settings.tier3_blocking: false` |
| Release owner review | off | `settings.release_owner_review: false` |
| Models | the Cursor model named in `pr-review-cost-efficiency.md` §Cloud Agent model policy, for every worker action | config `cursor_model_*` |
| `main` ruleset | add `execute-plan-scope` pinned to 15368; thread resolution on; keep strict and reviews 0 | runbooks §7.2 |
| Integration ruleset | new, contexts pinned, no bypass | runbooks §7.2 |
| Repo setting | **Allow auto-merge** on (currently off) | runbooks §7.3 |
| Kill switch | `EXECUTE_PLAN_DRIVER` = `dry-run` after WP7b, `on` from WP9 | runbooks §7.4 |

## Order and hand-off points

```
Phase 0 decisions ✔ → §7.1 identity + repo secret ✔ (Cursor `GH_TOKEN` = bot; owner via `/runasme`)
WP1 client ─┐                          WP7c Cursor launch adapter (parallel, Cursor)
WP2 scope ──┼→ WP3 approval/init → WP4a decide → WP4b tick → WP5 UAT
            │                                                   ↓
            │                         WP6a Cursor skills ┐      ↓
            └→ WP7a scope check + CI ────────────────────┼→ WP7b approve + driver (dry-run)
                                      WP6b Claude/docs ──┘      ↓
                                     WP8 rulesets + live verification (owner applies §7.2–7.3)
                                                                ↓
                                     WP9 proof run (first v2 plan)  ← gate for trusting v2
                                                                ↓
                                     WP10 retirement
```

Owner hand-offs: Phase 0; identity; merge of each WP PR; after WP7b (secret, `dry-run`); WP8
steps 3 and 5; the proof-run approval comment; go / no-go after WP9. Who builds which WP and the
prompts to paste: [work-split-and-prompts.md](./execute-plan-v2/work-split-and-prompts.md).

## Live GitHub facts the design relies on (read 2026-10-15)

- `main` ruleset 18979034 "Main protection" (active, no bypass actors): `non_fast_forward`;
  required checks `Analyze JavaScript` and `ci-gate / CI passed`, both pinned to integration
  15368, **strict = true**; `pull_request` with 0 reviews, `required_review_thread_resolution:
  false`, `require_extra_approval_for_unattributed_changes: true`; `copilot_code_review` (drafts
  included). Tag rulesets "UAT tag" and "PROD tag" active.
- Repo: public, owner type `User`, `allow_auto_merge = false`, squash and merge commits allowed,
  `delete_branch_on_merge = true`.
- `ci.yml` (`name: CI`) runs the PR tier on PRs into `main`, `cursor/*-integration-*`, `claude/**`.
- UAT chain: `pre-uat-e2e.yml` (push to `main`, `workflow_dispatch`, `cancel-in-progress: true`,
  9 shards + job `Pre-UAT E2E gate`) → `promote-uat.yml` (tags only when `main` HEAD equals the
  tested SHA; annotated tags `uat-YYMMDD-<PR>`) → `deploy-uat.yml` (jobs `Resolve deploy
  trigger`, `Build and deploy to UAT`, `UAT post-deploy smoke`, `Prod ready`, …).
- Deploy UAT runs conclude `success` even when nothing is deployed: 3 of the last 8 runs had
  every deploy job `skipped` (e.g. run 38599483437). The `Prod ready` job log carries
  `DEPLOY_REF: uat-…` and `gate_failure_class=none|infra_only|code` (run 38587026601).
- Last 30 runs: Pre-UAT 24 green / 4 red / 2 cancelled; Promote 6 throttle skips; Deploy 29 / 1.
- Neither `scripts/execute_plan_runtime.test.js` nor any `.github/scripts/*.test.js` runs in CI today.

## 10. Risks, residuals, rollback

| Risk | Mitigation | Rollback |
|------|-----------|----------|
| Driver launches in a loop | lease, launch budgets, daily cap, one global concurrency group, kill switch | `EXECUTE_PLAN_DRIVER=off` |
| Scope check blocks unrelated PRs | success for every non-plan PR; WP8 probe before the ruleset change | owner removes `execute-plan-scope` from the ruleset |
| Auto-merge lands after a STOP | `enforce-stop` disables auto-merge and turns the scope check red | `revoke-autonomous <id>` or label |
| Bot forges a passing check | contexts pinned to GitHub Actions; PATs cannot create check runs | — |
| Bot token leaks | `repo` scope only, no `workflow`, no admin; no secrets in `pull_request_target` | rotate the PAT; remove the collaborator |
| Pre-UAT red for reasons outside the plan | baseline comparison → `awaiting-main-green` ≤ 6 h → STOP `main-red`; resume later | `resume-autonomous` |
| Deploy failure misclassified | repo's own `gate_failure_class`; unknown → STOP, never remedial | manual deploy per `docs/e2e/uat-promote-manual.md` |
| A STOP strands merged phases | `resume-autonomous` with the same hash | — |
| v1 plans break during the build | v1 code untouched until WP10 | revert WP10 |
| Cursor API shape changes | one adapter (WP7c) with request tests | driver `dry-run` |

Residual: on Cursor cloud a turn can end at any time; the design makes that cost minutes, not the
programme. Each WP is one PR and reverts independently; safe reversal order is WP10 → WP8 → WP7b →
WP7a/WP7c → WP6a/WP6b → WP5 → WP4b → WP4a → WP3 → WP2 → WP1.
