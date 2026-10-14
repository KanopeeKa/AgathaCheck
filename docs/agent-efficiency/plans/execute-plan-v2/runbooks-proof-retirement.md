---
title: Execute-plan v2 — owner runbooks, proof run, retirement
owner: Kanopee
audience: both
status: active
last_updated: 2026-10-15
tags: [agent, execute-plan, autonomy, runbook]
---
# Execute-plan v2 — owner runbooks, proof run, retirement

Part of [execute-plan-v2.md](../execute-plan-v2.md). §7 is done by the owner; §8 (WP9) and §9
(WP10) by the executor with the owner hand-offs marked.

## 7. Owner runbooks

### 7.1 Identity (prerequisite for the driver — B1, B6)

**Path A — machine user with a classic PAT (default).**
1. Create a second GitHub account for the bot (GitHub permits one machine account per person).
   Name it; write the login into `.github/execute-plan.config.json` → `bot_login` (WP7 PR).
2. Repo → Settings → Collaborators → invite the bot with **Write**; accept from the bot account.
3. Bot account → Settings → Developer settings → Personal access tokens (classic) → scopes:
   **`repo` only** (no `workflow`, no `admin:*`); expiry 90 days; put the renewal date in your calendar.
4. Repo → Settings → Secrets and variables → Actions → secret `EXECUTE_PLAN_BOT_TOKEN` = that token.
5. Cursor → cloud agent settings → secrets: set `GH_TOKEN` to the same token, replacing your own,
   so workers act as the bot. Keep `cursor_api_key` as is.
6. Verify, from any shell with the token in `T`:
   - `curl -s -H "Authorization: token $T" https://api.github.com/user | jq -r .login` → bot login.
   - Push a branch that edits `.github/workflows/actionlint.yml` with the token → GitHub rejects it
     ("refusing to allow a Personal Access Token to create or update workflow"). Delete the branch.
   - After WP7: a PR merged by the bot token triggers **Pre-UAT E2E** (check the Actions tab).

**Path B — GitHub App (driver only; workers still need Path A).**
1. Settings → Developer settings → GitHub Apps → New: permissions Contents RW, Pull requests RW,
   Issues RW, Metadata R, **Workflows: none**; no webhooks; install on `AgathaCheck`.
2. Secrets `EXECUTE_PLAN_APP_ID`, `EXECUTE_PLAN_APP_PRIVATE_KEY`; workflows mint a token with
   `actions/create-github-app-token@v2` and export it as `EXECUTE_PLAN_BOT_TOKEN` for the step.
3. `bot_login` = `<app-slug>[bot]`.

Why not a fine-grained PAT: the repo is owned by a personal account, and a fine-grained token can
only target resources owned by its own user or an organisation. Moving the repo to a free
organisation would enable it; that is a separate decision.

### 7.2 Rulesets

**Integration branches — create** (`gh api -X POST repos/KanopeeKa/AgathaCheck/rulesets --input integration-ruleset.json`):
```json
{
  "name": "Execute-plan integration",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["refs/heads/cursor/*-integration-*"], "exclude": [] } },
  "bypass_actors": [ { "actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always" } ],
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "pull_request", "parameters": {
        "required_approving_review_count": 0, "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false, "require_last_push_approval": false,
        "required_review_thread_resolution": true,
        "allowed_merge_methods": ["squash", "merge"] } },
    { "type": "required_status_checks", "parameters": {
        "strict_required_status_checks_policy": false, "do_not_enforce_on_create": true,
        "required_status_checks": [ { "context": "execute-plan-scope" }, { "context": "ci-gate / CI passed" } ] } }
  ]
}
```
**VERIFY** before applying: `actor_id: 5` is the Admin repository role in your account
(`gh api repos/KanopeeKa/AgathaCheck/rulesets/18979034 --jq .bypass_actors`), and
`allowed_merge_methods` is accepted by the API version in use (drop the key if rejected; then set
the repo-level merge methods instead). `do_not_enforce_on_create` lets the approve workflow create
the branch. The bot (Write) cannot bypass; you (Admin) can.

**`main` — edit ruleset 18979034 "Main protection":** `gh api repos/KanopeeKa/AgathaCheck/rulesets/18979034 > main-ruleset.json`,
add `{ "context": "execute-plan-scope" }` to `required_status_checks`, keep `strict = true`,
keep reviews 0 and `copilot_code_review`; recommended: set `required_review_thread_resolution: true`
in the `pull_request` rule so Copilot threads must be resolved before auto-merge (matches the
repo's PR-review policy). Apply with `gh api -X PUT repos/KanopeeKa/AgathaCheck/rulesets/18979034 --input main-ruleset.json`.
Verify: `gh api repos/KanopeeKa/AgathaCheck/rules/branches/main --jq '.[] | select(.type=="required_status_checks") | .parameters.required_status_checks[].context'`
lists three contexts. Do this only after WP8 step 1 proved the check appears on PR heads.

### 7.3 Repository settings

`gh api -X PATCH repos/KanopeeKa/AgathaCheck -F allow_auto_merge=true` (currently `false`). Keep
`allow_squash_merge` and `allow_merge_commit` true (sync PRs need merge commits), keep
`delete_branch_on_merge` true.

### 7.4 Secrets and variables

| Name | Kind | Value |
|------|------|-------|
| `EXECUTE_PLAN_BOT_TOKEN` | secret | §7.1 |
| `cursor_api_key` | secret | exists |
| `EXECUTE_PLAN_DRIVER` | variable | `dry-run` after WP7; `on` after WP8; `off` = kill switch |

Owner-only maintenance: PAT renewal (90 d), reviewing `needs-owner` issues, removing
`autonomous-revoked`/`needs-owner` labels after a decision (a removed label does not restart a
run; re-approval is impossible by design — start a new plan).

## 8. Proof run (WP9) — the first v2 plan

**Plan id:** `proof-build-label-7f3a` (the contracts §3.1 example). **Precondition:** WP1–WP8
done, `EXECUTE_PLAN_DRIVER=on`, `main` quiet (no other programme merging that day).

**VERIFY before `init`:** the health route and its test file —
`rg -n "health" server/routes server/app.js server/index.js 2>/dev/null | head -5` — and replace
`server/routes/health.js` / `server/test/health.test.js` in the plan's yaml scope with the real
paths. The hash is computed at `init`, so the example hash in contracts §3.1 will differ; that is
expected.

**Plan file `.agents/plans/proof-build-label-7f3a.md`** (exact content; adjust paths per VERIFY):
````markdown
# Proof run: UAT build label

## Goal
Prove execute-plan v2 end to end: two phases on an integration branch, one release PR to main,
Pre-UAT E2E, promotion and Deploy UAT, with no owner message after the approval comment.

## Phases

### Phase 1 — Server build label
```yaml
allowed_paths: [server/routes/health.js, server/test/health.test.js]
forbidden_paths: []
allowed_exceptions: [tests]
companions: []
exit_checklist: [health unit test green, pre-push-changed green]
```
Scope: add the JSON field `proof_label` with the constant value `execute-plan-v2-proof` to the
`GET /backend/health` response, plus a unit test asserting it.
Out of scope: any other route, any Flutter file.

### Phase 2 — Docs note
```yaml
allowed_paths: [docs/e2e/uat-deploy-tiers.md]
forbidden_paths: []
allowed_exceptions: [docs]
companions: []
exit_checklist: [docs gates green]
```
Scope: add one line under "Execute-plan v2 observes this chain": `Proof run: proof-build-label-7f3a (<date>)`.
Out of scope: everything else.

## Proof on UAT
`curl -s https://uat.agathatrack.com/backend/health | jq -r .proof_label` prints `execute-plan-v2-proof`.
````

**Procedure**
1. Executor: on branch `cursor/proof-build-label-7f3a-init`, add the plan file, run
   `node scripts/execute_plan_runtime.js init proof-build-label-7f3a --window-days 3`. The turn ends.
2. Owner: paste the printed approval line as a comment on the control issue. **From here the only
   human actions are the two drill actions below.**
3. Drill 1 — injected phase-CI failure: when phase 1's PR is marked ready, the owner pushes one
   commit to the phase-1 branch that flips the new assertion to an impossible value. Expected:
   red `ci-gate` → `tick` → `fix-ci` → worker launched → fix → green → auto-merge.
4. Drill 2 — forced turn end: while phase 2's worker is running (draft PR exists), the owner cancels
   the Cursor agent from the Cursor dashboard. Expected: within ≤ 30 min the heartbeat sees a dead
   lease and relaunches with the handoff; phase 2 completes.
5. Watch nothing else. Expected sequence on the control issue: `phase:1 … merged` →
   `phase:2 … merged` → `sync` (only if `main` moved) → `release:open` → `release:merged` →
   `awaiting-preuat` → `awaiting-promote` → `awaiting-deploy` → `complete`, issue closed by `tick`.

**Record** (in the control issue's final status comment and in `docs/agent-efficiency/plans/execute-plan-v2/proof-run-results.md`):
launches per phase (expected: p1 = 2, p2 = 2, release = 0), total wall time, Pre-UAT/Deploy run
URLs, tag name, Cursor cost from the usage page, number of human messages (expected 0 besides the
approval and the two drill actions), every `wait` reason seen.

**Pass:** issue closed by `tick` with the four evidence links; the curl prints the label; no STOP
occurred; launches within budgets. **Fail:** any STOP, any human message needed, or the issue not
closed within the window. On fail: fix the cause in a normal PR and rerun with a **new plan id**
(plans are immutable), e.g. `proof-build-label-7f3b`.

**UAT failure drill (separate; owner opt-in).** Default: fixtures only — WP5 already replays real
red, cancelled and throttle-skipped runs. Live option, on a quiet day: plan `proof-uat-drill-<id>`
whose single phase makes one Playwright assertion under `e2e/` fail deterministically (`tests`
exception). Expected: release merges → Pre-UAT red, app-caused (baseline green) → `remedial` →
worker fixes the assertion on `cursor/<id>-remedial-1` → merge → green → tag → deploy →
`complete`. It blocks UAT promotion for one to two hours; schedule accordingly.

## 9. Retirement PR (WP10) — only after §8 passes

**Branch:** `claude/execute-plan-v2-wp10` · **Precondition:** no open v1 plan
(`gh issue list -R KanopeeKa/AgathaCheck -l execute-plan -s open` shows only v2 issues).

**Code**
- Remove v1 paths: `set-phase`, `sync-runtime`, `--labels` on `gate`, `--fix-hash`, v1 schema
  routing, `checkAutonomyGate` label handling (`scripts/lib/execute_plan_artifacts.js:315`),
  `formatAgentNextStep` (`:297`); keep `gate` as an alias of `tick`.
- `.agents/plans/_example.snapshot.json` (v1) → delete; pre-push validates only the v2 example.
- `scripts/babysit_uat_watch_preuat.sh` → thin wrapper around `watch-preuat` or delete if nothing
  calls it (`rg -n "watch_preuat" scripts .cursor docs`).
- `scripts/lib/execute_plan_project.js` → use the WP1 client; no `gh` left in `scripts/lib/execute_plan_*`.
- Decide and do one: fold `agent-pr-safety-gate.yml` into `execute-plan-scope.yml`, or extend it
  to `cursor/*-integration-*`. One gate afterwards.
- Remove `proof_label` from the health route (or rename it `deployed_marker` if kept on purpose).

**Docs**
- Both execute-plan skills: delete the v1 sections; the skill is the v2 loop only.
- `docs/agent-efficiency/execute-plan-instruction-stack.md`: delete the platform-override table
  and § Cloud turn mechanics; keep § v2 loop.
- `docs/agent-efficiency/autonomous-pr-policy.md`: delete rows 45–51 (turn-boundary rules).
- `AGENTS.md` §Execute-plan: v2 paragraph only.
- `.agents/memory/execute-plan-autonomy.md`: delete; `MEMORY.md` keeps the v2 index line.
- `docs/agent-efficiency/execute-plan-memory-1470.md`: append "2026-10: superseded — liveness and
  integrity are now mechanisms (execute-plan v2); see `docs/agent-efficiency/plans/execute-plan-v2.md`."
- `docs/agent-efficiency/plans/execute-plan-v2.md`: add `Shipped: <date>` under the title; link
  `proof-run-results.md`.
- `docs/design/terminology.md` / `docs/agent-efficiency/README.md`: update any "execute-plan"
  entries that describe v1 commands (`rg -n "set-phase|sync-runtime|fix-hash" docs .cursor AGENTS.md`).

**Acceptance:** `./scripts/pre-push.sh` green; `rg -n "set-phase|sync-runtime|--fix-hash|forbidden closers" --glob '!docs/agent-efficiency/plans/**' . ` returns nothing; docs link check green.

**Rollback:** revert the retirement PR; v1 returns intact (it was never modified before this PR).
