---
title: Execute-plan v2 — build spec (merged + deployed to UAT)
owner: Kanopee
audience: agent
status: active
last_updated: 2026-11-11
tags: [agent, execute-plan, autonomy, uat]
---
# Execute-plan v2 — build spec

**Shipped:** 2026-11-01 — proof run GO ([proof-run-results.md](./execute-plan-v2/proof-run-results.md), issue #1979); v1 runtime retired in WP10.

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
| WP11–WP12 worker identity hardening (+ kickoff prompt) | [`execute-plan-v2/work-packages-hardening.md`](./execute-plan-v2/work-packages-hardening.md) | WP11, WP12 |

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
| 5 | Scope result = commit status set by GitHub Actions (was an API check run until 2026-11-02; a PAT-set status never counts); `enforce-stop` turns it red on open PRs | contracts §3.7, WP7a, WP7b, decision log 2026-11-02 |
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
| Budgets | CI attempts **8** per PR (cap 15), launches **15** per phase (cap 25), remedial **6** (cap 10), sync resolves **5** (cap 8), daily launches **80** per plan (cap 150) — reaching the daily cap **waits** until the next UTC day, it never stops the plan | snapshot `settings.budgets` (≤ caps) |
| Tier 3 live E2E | advisory | `settings.tier3_blocking: false` |
| Release owner review | off | `settings.release_owner_review: false` |
| Models | the Cursor model named in `pr-review-cost-efficiency.md` §Cloud Agent model policy, for every worker action | config `cursor_model_*` |
| `main` ruleset | add `execute-plan-scope` pinned to 15368; thread resolution on; **strict false**; reviews 0 | runbooks §7.2 |
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
  15368, **strict = true** on the 2026-10-15 read (superseded 2026-11-11: strict must be **false**; a clean behind PR may merge — bot PUT of ruleset 18979034 returned HTTP 404, so an admin still applies it); `pull_request` with 0 reviews, `required_review_thread_resolution:
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
| Bot forges a passing check | contexts pinned to GitHub Actions: a status the bot sets with its PAT is refused by the ruleset ("not set by the expected GitHub app") and ignored by `observe` | — |
| Bot token leaks | `repo` scope only, no `workflow`, no admin; no secrets in `pull_request_target` | rotate the PAT; remove the collaborator |
| Pre-UAT red for reasons outside the plan | baseline comparison → `awaiting-main-green` ≤ 6 h → STOP `main-red`; resume later | `resume-autonomous` |
| Deploy failure misclassified | repo's own `gate_failure_class`; unknown → STOP, never remedial | manual deploy per `docs/e2e/uat-promote-manual.md` |
| A STOP strands merged phases | `resume-autonomous` with the same hash | — |
| v1 plans break during the build | v1 code untouched until WP10 | revert WP10 |
| Cursor API shape changes | one adapter (WP7c) with request tests | driver `dry-run` |

## Decision log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-11-01 | **WP10:** Keep both `execute-plan-scope` (required, trusted-code for plan PRs) and `agent-pr-safety-gate.yml` (advisory forbidden-path for non-plan agent PRs) until [#1980](https://github.com/KanopeeKa/AgathaCheck/issues/1980) ships a single owner-override gate. | Plan PRs need strict scope enforcement now; prefix-based advisory gate still catches non-plan agent edits without blocking every PR on day one. |
| 2026-11-01 | **WP10:** Remove `proof_label` from `/backend/health`; v1 CLI (`set-phase`, `sync-runtime`, `--fix-hash`, label-based `gate`) removed; `gate` aliases `tick`. | Owner GO after proof run 7f3b; historical schema-1 snapshots remain on disk as records only. |
| 2026-11-02 | **WP11:** Agents launched by the driver or by issue/dispatch get `OWNER_GH_TOKEN` and `BOT_GH_TOKEN` blanked through launch `envVars`; a worker `tick` exits 3 without reading or writing when `OWNER_GH_TOKEN` is set, and skills run it as `env -u OWNER_GH_TOKEN -u BOT_GH_TOKEN … tick`. Shipped in [#1986](https://github.com/KanopeeKa/AgathaCheck/pull/1986). Launch transport: Cursor API rejects empty `envVars` values ([#1991](https://github.com/KanopeeKa/AgathaCheck/pull/1991) strips blank keys at the HTTP boundary). | Least privilege: workers act as `bot_login` only; the check fails closed if a launch cannot blank a secret; `env -u` works per command because agent shells are often fresh. |
| 2026-11-02 | **WP11 owner probe (Actions [run 41368243319](https://github.com/KanopeeKa/AgathaCheck/actions/runs/41368243319), agent `bc-d92a8dfe-98a3-4535-b8f4-e7652bcb5e3f`):** probe agent reported `OWNER_GH_TOKEN present`, `BOT_GH_TOKEN present`, `GH_TOKEN present`, `EXECUTE_PLAN_TOKEN present`; `CLOUD_AGENT_INJECTED_SECRET_NAMES=GH_TOKEN,BOT_GH_TOKEN,OWNER_GH_TOKEN,EXECUTE_PLAN_TOKEN` despite launch `envVars` of bot `GH_TOKEN`/`EXECUTE_PLAN_TOKEN` only (`probe-not-a-token`). **Outcome: blank/omit does not override dashboard secrets.** Keep worker `tick` guard; do not start execute-plan runs until Cursor supports removing owner secrets per launch (or probe is re-run with a passing result). WP12 code may still land; do not label plans `autonomous-approved` for production use until launch isolation is verified. | Matches work-packages-hardening §Owner probe failure row; driver launches would still expose owner token to workers today. |
| 2026-11-02 | **WP12 (planned):** An approve or resume comment counts only with an acknowledgement from the approve workflow on `main`, posted when the comment arrived and no plan worker was running (Cursor run status only; `UNKNOWN` counts as running). Posted while a worker runs: ignored with a note if the plan is already stopped, otherwise the plan stops with `needs-owner`. | Authorizations come from the owner and are confirmed by trusted code at the time they are posted; a re-post after the worker finishes is the only cost of a false rejection, and a stopped plan never loops into a second stop. |
| 2026-11-02 | **Scope result moves from a check run to a commit status** (owner decision, option C). The Checks API attaches a check run created with a workflow `GITHUB_TOKEN` to *some* GitHub Actions check suite on the commit (the scope run's, governance hints', …); when that suite's run was cancelled, the ruleset no longer counts the check (merge → 405 `Required status check "execute-plan-scope" is expected`), while the API still reports it green. This stopped [#1997](https://github.com/KanopeeKa/AgathaCheck/pull/1997) and [#1998](https://github.com/KanopeeKa/AgathaCheck/pull/1998) (`merge-blocked`). A commit status has no suite. Probe [#2001](https://github.com/KanopeeKa/AgathaCheck/pull/2001) (temporary ruleset pinned to 15368): an owner-PAT status was refused ("not set by the expected GitHub app"); the same context set by a `pull_request` workflow with `GITHUB_TOKEN` (creator `github-actions[bot]`) let the PR merge. Rulesets unchanged (context names and pin stay). `observe` trusts only `github-actions[bot]` statuses and falls back to a legacy check run on heads published before the switch; `publishScopeCheck` also turns such a legacy run the same colour. A green plan result is re-checked against the STOP state just before posting (`publishScopeResult`; re-check error → `drift`), so a run that evaluated before `enforce-stop` cannot turn the head green again; the scope and driver workflows have `statuses: write` (the approve workflow did too until it stopped running passes inline, row below). | No new App or secret; statuses cannot be orphaned by cancelled runs; the forge guarantee is the ruleset's app pin, now probed for statuses. |
| 2026-11-02 | **Driver recovers an uncounted or stale scope check instead of waiting or stopping at once** (owner request). PR-ladder 3b: a `plan-stopped` scope status on a running plan (left by `enforce-stop`; nothing re-ran the scope workflow after `resume-autonomous`, so every resume used to launch a wasted `fix-ci`) → driver `republish-scope`. PR-ladder 10a: a required check still `missing` 15 min after every head check run finished, or 2 h after the head commit → `republish-scope` for the scope check, else STOP `check-missing` (no worker: a worker has nothing to fix for an absent check). Merge refusals (both `merge` and the `arm-auto-merge` clean-status fallback, which used to fail the pass on every run): 405 for an uncounted `execute-plan-scope` → republish once per head per epoch, then STOP `check-missing`. Ledger `status.dispatched.scope_republish`. | Every repair is bounded (one republish per head per epoch) and ends in a STOP that names the check; `wait(checks)` can no longer last forever on an absent check. |
| 2026-11-02 | **Out-of-scope fixes: the rule is narrowed to the plan's goal** (owner request). "Changing scope means a new plan" becomes "changing the plan's goal means a new plan"; a fix outside the approved paths that the plan needs to land is allowed when linked to the plan (`Unblocks: plan <id> phase <n>`), as an ordinary PR into the integration branch (category `null`: not evaluated by the scope check, and red `plan-stopped` while the plan is stopped, so resume first and hold the phase PR). The `Unblocks:` link and path limits are a convention until the `support` category exists. Driver change limited to the `ci-budget` detail and the `fix-scope` worker text. | With #2003/#2004 the remaining scope stop is a real out-of-scope need, which used to end in an opaque `ci-budget` stop and a new plan. Workers cannot record a STOP, so the driver names the route. A driver-tracked `support` category (PR category, `Unblocks:` check, per-phase budget, release-scope union) is deferred: it widens the required scope check, so it needs an owner decision. |
| 2026-11-02 | **Every driver pass runs in the driver workflow's concurrency group** (owner sign-off on [#2005](https://github.com/KanopeeKa/AgathaCheck/issues/2005)). The approve workflow used to run a pass inline in its per-issue group, so it could run alongside a driver pass for the same plan: both read the status comment, could pick the same action (a duplicate worker launch at worst) and the last status write won. It now dispatches `execute-plan-driver.yml` with `plan_id` after its own writes. It does not join the `execute-plan-driver` group itself: GitHub keeps one pending job per group and cancels the older pending one, which could drop an approval. The approve job loses `statuses`/`checks` write, `pull-requests` write and `CURSOR_API_KEY`. | One place runs passes; an approval is never cancelled; a dispatched pass replaced while pending costs at most the 30-minute heartbeat, and `revoke` is also enforced by the `autonomous-revoked` label event. |
| 2026-11-02 | **Worker prompt: verify before every push; report out-of-scope fixes** (owner review of the `household-cleanup-609f` phase 6 stops). The handoff prompt now requires `./scripts/pre-push-changed.sh` green before every push (format failures were 4 of the 6 failing heads on PR #2000) and tells a worker whose fix needs a protected path, CI gate or budget file to stop and report `worker done: blocked <check>: <reason>`. `ci-budget` stays an owner stop; auto-resume and not counting unfixable failures were considered and rejected (the resume is the owner's approval; a conditional `resume … after #<pr>` needs a separate security review of the approve workflow). | A budget exhausted by fixable mistakes is avoidable at the source; one that is exhausted by an out-of-scope gate needs the owner either way. |
| 2026-11-02 | **Caps are loop breakers, and a bundle-size overshoot is raised, not trimmed** (owner request, after household-cleanup-609f phase 6: a 7 KB / 0.1% overshoot of `maxMainDartJsBytes` cost 6 worker launches, 3 `ci-budget` stops and a dropped feature). Defaults/caps for new plans: CI attempts 8/15, launches per phase 15/25, remedial 6/10, sync 5/8, daily 80/150; per-phase companion globs 12; `COMPANION_CAP` 30. `scripts/ci/web-bundle-budget.json` is a companion only when an in-scope phase is scoped under `flutter_app/`, so such a phase PR may raise the cap in its own diff and no other plan PR can. The handoff prompt tells workers to raise it (measured size + ~1%, before/after bytes in the PR body) when the overshoot is planned code, never to cut planned scope, and to make one trimming attempt only for a jump over ~1.5% or an unexplained one. Plans approved before this change keep their snapshot budgets (the hash covers them). | A gate that fails identically on every push plus a short attempt limit can only end in a stop or in cut scope; the budget exists to catch unplanned growth, which the PR body now records. |
| 2026-11-02 | **Legacy `execute-plan-scope` check-run fallback removed** ([#2002](https://github.com/KanopeeKa/AgathaCheck/issues/2002)). Precondition checked first: no open plan PR or plan control issue existed, so no head could still carry only a check run. `observe` / `watch-ci` read the scope result from the trusted `github-actions[bot]` status only (a check run of that name is ignored; no status = `missing`), `failed_attempts` no longer counts scope check runs, `publishScopeCheck` only posts the status, and the unused `createCheckRun` / `updateCheckRun` client methods are gone. Owner-confirmed workflow change: `execute-plan-scope.yml` drops `checks: write`; `execute-plan-driver.yml` keeps only `checks: read` (observe reads CI check runs). Not an execute-plan run: every file involved is in the protected set (`scripts/lib/execute_plan_*`, `.github/**`, the v2 docs), which no plan PR may change. | One source of truth for the scope result; the old path could only matter for heads that no longer exist. |
| 2026-11-03 | **WP12 shipped:** Authorization acknowledgements (`execute_plan_ack.js`), `findControlComments` requires `{ accepted }`, approve handler gate (running worker table), release-scope union via merged side PRs (`execute_plan_support.js`). Driver passes still share one global `execute-plan-driver` concurrency group (per-`plan_id` groups remain a possible v2 improvement). | Closes the post-#2003 gap where unacknowledged owner comments and integration-only side fixes blocked release scope. |
| 2026-11-11 | **Plan C P1 (#2259):** `observe` prefers a merged phase PR over a newer open duplicate on the same head; `decide` treats `merged_into_integration` as phase-complete so merged work never relaunches `implement`. | Duplicate subscription phase PRs ([#2236](https://github.com/KanopeeKa/AgathaCheck/pull/2236) vs [#2237](https://github.com/KanopeeKa/AgathaCheck/pull/2237)) showed the bug: `newest(pulls)` picked the later open draft after an earlier squash-merge. |
| 2026-11-11 | **Plan C P2 (#2259):** `init` and `validateSnapshotV2` warn on cross-plan wait phrases in plan markdown (warning only); landing limits documented in `plan-template.md` → `parallel-programmes.md`. | Roadmap plans often prose-coordinate with `wait for …` / `human_pause` / landing slots; v2 cannot block mid-plan on another programme. |
| 2026-11-11 | **Plan C P3a (#2259):** Playwright `expectSingleSemanticsNode` in `e2e/playwright/support/flutter.ts` fails when duplicate `flt-semantics-identifier` nodes exist. | Catches duplicate semantics before Pre-UAT when page objects interact by identifier. P3b (CI affected-domain mapping) deferred until owner approves `ci.yml` E2E changes on #2259. |
| 2026-11-03 | **Init branch guard at authoring time** (no approve gate change). `init` compares committed diff vs `main` with `--no-renames` and exits 3 when paths other than the two plan files are present; approve rejection uses the same actionable message. Delivery docs and README rows stay on normal PRs to `main`. Optional future `init_files` with hashed bytes remains a separate escalation. | Catches bundled init PRs on day 0; approve still seeds integration from a two-file-only SHA with no CI or scope check on that step. |
| 2026-11-03 | **Approve init check is rename-aware.** `compare(main…sha)` unions `filename` and `previous_filename` so a rename into a plan path cannot hide a deleted file on the integration tip. | Matches release scope's path union; closes the rename loophole left by filename-only approve checks. |
| 2026-11-04 | **Sync resolves can merge, and only one is open at a time** (owner request after [#2074](https://github.com/KanopeeKa/AgathaCheck/pull/2074): five resolve PRs, all green CI, all red `execute-plan-scope` with 58 `protected`/`forbidden` files merged in from unrelated `main` commits). The scope check skips files identical to the `main` tip for `sync-resolve` as it already did for `release` (schema §scope 2c); files the resolve changes vs `main` are still checked. S1b drives an open `cursor/<id>-sync-*` PR through the PR-ladder (draft action `resolve-sync`, method `merge`) instead of launching a new resolve branch on every pass (`observe` adds `sync.resolve_pr`). | `main`'s content is already reviewed and merged; checking it against one plan's scope blocked every sync once `main` moved outside that scope. A resolve PR that is blocked now reaches a worker fix or a named STOP (`worker-blocked`, `ci-budget`) instead of burning the sync budget. |
| 2026-11-11 | **Light-plan releases do not catch integration up to `main`.** Ruleset 18979034 must keep `strict_required_status_checks_policy` false. A `MERGEABLE` integration → `main` PR squash-merges while `BEHIND`. `main` is merged into the integration branch only when that release is `CONFLICTING` (babysit preflight exit `4`). The bot could not apply the ruleset edit (HTTP 404). Until an admin sets the flag, GitHub still rejects a behind merge; that rejection is not a reason to open a sync PR. The execute-plan driver still opens a sync PR when it sees the integration branch behind `main` before release (S1); that runtime is unchanged. | Concurrent light-plans were each opening a full-CI sync PR whenever another release landed, including when `git merge-tree` was clean (#2269 / #2294). Pre-UAT on the merge SHA checks the combined tree. |

Residual: on Cursor cloud a turn can end at any time; the design makes that cost minutes, not the
programme. Each WP is one PR and reverts independently; safe reversal order is WP10 → WP8 → WP7b →
WP7a/WP7c → WP6a/WP6b → WP5 → WP4b → WP4a → WP3 → WP2 → WP1.
