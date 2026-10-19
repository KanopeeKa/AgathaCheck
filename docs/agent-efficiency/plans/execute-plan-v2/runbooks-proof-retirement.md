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
(WP10) by an executor, with the owner steps marked.

## 7. Owner runbooks

### 7.1 Identity (prerequisite for the driver — B1, B6)

**Status (2026-10-15):** done with Path A — bot `pawpet-bot` is a collaborator and the repo secret
`EXECUTE_PLAN_BOT_TOKEN` is set; step 5 is pending until WP8.

**Path A — machine user with a classic PAT (default).** Fine-grained PATs cannot target a repo
owned by another personal account (`owner.type = User`, live read), so this is the available path.
1. Create a second GitHub account for the bot (GitHub permits one machine account per person).
   Its login goes into `.github/execute-plan.config.json` → `bot_login` (WP7a PR).
2. Repo → Settings → Collaborators → Add people → the bot login; accept from the bot account. A
   repo owned by a personal account has no role picker: collaborators get push (write) access.
3. Bot account → Settings → Developer settings → Personal access tokens (classic) → scopes:
   **`repo` only** (no `workflow`, no `admin:*`); expiry 90 days; put the renewal date in a calendar.
4. Repo → Settings → Secrets and variables → Actions → secret `EXECUTE_PLAN_BOT_TOKEN` = that token.
5. **Do not change the Cursor `GH_TOKEN`** (it is the owner's identity for all Cursor work). Plan
   workers act as the bot because the driver passes `GH_TOKEN` and `EXECUTE_PLAN_TOKEN` (the bot
   token) in the launch request (`envVars` take precedence over dashboard secrets). The only other
   place the bot token goes in Cursor is a **temporary** secret named `BOT_GH_TOKEN` for WP8
   (set it before WP8, delete it after). Keep `cursor_api_key` as it is.
6. Verify from any shell with the token in `T`:
   - `curl -s -H "Authorization: Bearer $T" https://api.github.com/user | jq -r .login` → the bot login.
   - Pushing a branch that edits `.github/workflows/actionlint.yml` with this token is rejected
     ("refusing to allow a Personal Access Token to create or update workflow"). Delete the branch.
   - After WP7b: a PR merged by the bot token starts **Pre-UAT E2E** (Actions tab).

**Path B — GitHub App (driver only; workers still need Path A).** Permissions Contents RW, Pull
requests RW, Issues RW, Metadata R, Workflows **none**; install on `AgathaCheck`; secrets
`EXECUTE_PLAN_APP_ID` + `EXECUTE_PLAN_APP_PRIVATE_KEY`; the workflows mint a token with
`actions/create-github-app-token@v2` and export it as `EXECUTE_PLAN_BOT_TOKEN`; `bot_login` =
`<app-slug>[bot]`. Only worth it if PAT renewal becomes a burden.

### 7.2 Rulesets

Every required context is **pinned to GitHub Actions** (`integration_id: 15368`, the id the live
`main` ruleset already uses). Without the pin, the bot's PAT could post a commit status with the
same name and satisfy the check.

**Integration branches — create** (`gh api -X POST repos/KanopeeKa/AgathaCheck/rulesets --input integration-ruleset.json`):
```json
{
  "name": "Execute-plan integration",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["refs/heads/cursor/*-integration-*"], "exclude": [] } },
  "bypass_actors": [],
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
        "required_status_checks": [
          { "context": "ci-gate / CI passed", "integration_id": 15368 },
          { "context": "execute-plan-scope", "integration_id": 15368 } ] } }
  ]
}
```
`bypass_actors` is empty like `main`'s ruleset (live read); as repo admin you can still edit or
disable the ruleset. If the API rejects `allowed_merge_methods`, drop that key (the repo already
allows squash and merge commits). `do_not_enforce_on_create` lets the approve workflow create the branch.

**`main` — edit ruleset 18979034 "Main protection":**
`gh api repos/KanopeeKa/AgathaCheck/rulesets/18979034 > main-ruleset.json`; in the
`required_status_checks` rule add `{ "context": "execute-plan-scope", "integration_id": 15368 }`;
keep `strict_required_status_checks_policy: true` (the driver runs `update-branch`), reviews 0 and
`copilot_code_review`; set `required_review_thread_resolution: true` in the `pull_request` rule so
review threads must be resolved before auto-merge. `require_extra_approval_for_unattributed_changes`
is currently `true`: keep it unless WP8 step 2 shows it blocks bot PRs, then set it to `false`.
Apply with `gh api -X PUT repos/KanopeeKa/AgathaCheck/rulesets/18979034 --input main-ruleset.json`.
Verify: `gh api repos/KanopeeKa/AgathaCheck/rules/branches/main --jq '.[] | select(.type=="required_status_checks") | .parameters.required_status_checks'`
lists three contexts, each with `integration_id: 15368`. Do this only after WP8 step 1 passed.

### 7.3 Repository settings

`gh api -X PATCH repos/KanopeeKa/AgathaCheck -F allow_auto_merge=true` (currently `false`). Keep
`allow_squash_merge` and `allow_merge_commit` true (sync PRs use merge commits) and
`delete_branch_on_merge` true (snapshots are read at `init_sha`, so deleted branches do not matter).

### 7.4 Secrets and variables

| Name | Kind | Value |
|------|------|-------|
| `EXECUTE_PLAN_BOT_TOKEN` | secret | §7.1 |
| `cursor_api_key` | secret | exists |
| `EXECUTE_PLAN_DRIVER` | variable | `dry-run` after WP7b; `on` for WP8 step 4 and from WP9; `off` = kill switch |

### 7.5 Day-to-day: approve, resume, revoke

- **Approve** a new plan: paste the exact line printed by `init` as a comment on its control issue.
- **When a run stops** (label `needs-owner`, reason in the status comment): fix the cause if needed
  (for example merge a fix to `main`), then remove `needs-owner` (and `autonomous-revoked` if
  present) and comment `resume-autonomous <plan_id> sha256:<same hash> until <ISO date ≤ 14 days ahead>`.
  Scope stays the same; time and budgets restart from that comment. Changing scope means a new plan.
- **Revoke**: add label `autonomous-revoked` or comment `revoke-autonomous <plan_id>`. Auto-merge
  is disabled and the scope check turns red on every open plan PR within one driver pass.
- **Kill switch**: set `EXECUTE_PLAN_DRIVER=off` — the approve and driver workflows stop acting at once.
- Maintenance: PAT renewal every 90 days.

## 8. Proof run (WP9) — the first v2 plan

**Plan id:** `proof-build-label-7f3a`. **Precondition:** WP1–WP8 done, `EXECUTE_PLAN_DRIVER=on`,
`main` quiet (no other programme merging that day). **Recommended executor for the init step:**
Cursor (it acts as the bot, which is the real path).

Facts already checked: `/backend/health` is defined inline at `server/bin/server.js:158`
(`createApp` is exported); route tests use `supertest` + `createApp(mockPool())` as in
`server/test/publicAccess.test.js`.

**Plan file `.agents/plans/proof-build-label-7f3a.md`** (exact content; replace `<date>` with the run date):
````markdown
# Proof run: UAT build label

## Goal
Prove execute-plan v2 end to end: two phases on an integration branch, one release PR to main,
Pre-UAT E2E, promotion and Deploy UAT, with no owner message after the approval comment.

## Phases

### Phase 1 — Server build label
```json
{ "allowed_paths": ["server/bin/server.js", "server/test/healthProofLabel.test.js"],
  "forbidden_paths": [], "allowed_exceptions": ["tests"], "companions": [],
  "exit_checklist": ["health proof-label test green", "pre-push-changed green"] }
```
Scope: in the `GET /backend/health` handler, add the JSON field `proof_label` with the constant
value `execute-plan-v2-proof` (keep `status: 'OK'`); add `server/test/healthProofLabel.test.js`
asserting both fields with `supertest` and `createApp(mockPool())`.
Out of scope: `/health`, any other route, any Flutter file.

### Phase 2 — Docs note
```json
{ "allowed_paths": ["docs/e2e/uat-deploy-tiers.md"],
  "forbidden_paths": [], "allowed_exceptions": ["docs"], "companions": [],
  "exit_checklist": ["docs gates green"] }
```
Scope: add one line under the section "Execute-plan v2 observes this chain":
`Proof run: proof-build-label-7f3a (<date>)`.
Out of scope: everything else.

## Proof on UAT
`curl -s https://uat.agathatrack.com/backend/health | jq -r .proof_label` prints `execute-plan-v2-proof`.
````

**Procedure**
1. Executor: create branch `cursor/proof-build-label-7f3a-init` from `main`, add the plan file, run
   `node scripts/execute_plan_runtime.js init proof-build-label-7f3a --window-days 3`. The session ends.
2. Owner: paste the printed approval line on the control issue. **From here the only human actions
   are the two drill actions.**
3. Drill 1 — injected phase-CI failure: when phase 1's PR is marked ready, the owner pushes one
   commit to the phase-1 branch that changes the expected value in the new test. Expected: red
   `ci-gate` → `fix-ci` → worker launched → fixed → green → auto-merge.
4. Drill 2 — forced turn end: while phase 2's worker runs (draft PR exists), the owner cancels the
   Cursor agent from the dashboard. Expected: within 30 min the heartbeat sees a dead lease and
   relaunches with the handoff; phase 2 completes.
5. Expected log on the control issue: `phase:pending … phase:merged` (×2) → `sync` (only if `main`
   moved) → `release:open` → `awaiting-preuat` → `awaiting-promote` (only if the throttle skipped)
   → `awaiting-deploy` → `complete`; the issue is closed by the driver.

**Record** (final status comment + `docs/agent-efficiency/plans/execute-plan-v2/proof-run-results.md`):
launches per phase (expected p1 = 2, p2 = 2, release = 0), wall time, Pre-UAT / Deploy UAT run
URLs, tag, Cursor cost, number of human actions (expected: approval + 2 drills), every `wait` reason seen.

**Pass:** issue closed by the driver with the four evidence links; the curl prints the label; no
STOP; launches within budget. **Fail:** any STOP, any extra human action, or the window expires.
On fail: fix the cause in a normal PR, then either `resume-autonomous` (same scope) or rerun with a
new plan id (`proof-build-label-7f3b`) if the plan itself was wrong.

**UAT failure drill (separate, owner opt-in).** Default: the WP5 scenarios already cover red,
cancelled, throttle-skipped and no-op runs. Live option on a quiet day: plan `proof-uat-drill-<4>`
whose single phase makes one Playwright assertion under `e2e/` fail deterministically (`tests`
exception). Expected: release merges → Pre-UAT red, app-caused (baseline green) → `remedial` →
worker fixes the assertion on `cursor/<id>-remedial-1` → merge → green → tag → deploy →
`complete`. It blocks UAT promotion for one to two hours.

## 9. Retirement PR (WP10) — only after §8 passes

**Recommended executor:** Claude Code · **Precondition:** no open v1 plan (open `execute-plan`
issues all have a v2 snapshot).

**Code**
- Remove v1 paths: `set-phase`, `sync-runtime`, `--labels` on `gate`, `--fix-hash`, v1 schema
  routing, `checkAutonomyGate` label handling (`scripts/lib/execute_plan_artifacts.js:315`),
  `formatAgentNextStep` (`:297`); keep `gate` as an alias of `tick`.
- Delete `.agents/plans/_example.snapshot.json` (v1); pre-push validates only the v2 example.
- `scripts/babysit_uat_watch_preuat.sh` → thin wrapper around `watch-preuat`, or delete it when
  `rg -n "watch_preuat" scripts .cursor docs` finds no caller.
- `scripts/lib/execute_plan_project.js` → use the WP1 client; no `gh` left in `scripts/lib/execute_plan_*`.
- One safety gate: extend `execute-plan-scope` to all agent PRs and delete `agent-pr-safety-gate.yml`,
  or keep both and document why (owner decision recorded in the PR).
- Remove `proof_label` from the health handler (or keep it renamed `deployed_marker` on purpose).

**Docs**
- Both execute-plan skills: delete the v1 sections; the skill is the v2 loop only.
- `docs/agent-efficiency/execute-plan-instruction-stack.md`: delete the platform-override table
  and § Cloud turn mechanics; keep § v2 loop.
- `docs/agent-efficiency/autonomous-pr-policy.md`: delete the turn-boundary rows of §Execute-plan
  overrides (lines 45–51 today).
- `AGENTS.md` §Execute-plan: v2 paragraph only.
- `.agents/memory/execute-plan-autonomy.md`: delete; `MEMORY.md` keeps the v2 line.
- `docs/agent-efficiency/execute-plan-memory-1470.md`: append "2026-10: superseded — liveness and
  integrity are mechanisms (execute-plan v2); see `docs/agent-efficiency/plans/execute-plan-v2.md`."
- `docs/agent-efficiency/plans/execute-plan-v2.md`: add `Shipped: <date>` and link `proof-run-results.md`.
- Update other v1 command mentions: `rg -n "set-phase|sync-runtime|fix-hash" docs .cursor AGENTS.md`.

**Acceptance:** `./scripts/pre-push.sh` green; `rg -n "set-phase|sync-runtime|--fix-hash" --glob '!docs/agent-efficiency/plans/**' .` returns nothing; `bash scripts/validate_docs.sh` green.

**Rollback:** revert the retirement PR; v1 returns intact (it was not modified before this PR).
