---
title: Execute-plan v2 — platform work packages WP6–WP8 and workflows
owner: Kanopee
audience: agent
status: active
last_updated: 2026-10-15
tags: [agent, execute-plan, autonomy, github-actions]
---
# Execute-plan v2 — platform work packages WP6–WP8 and workflows

Part of [execute-plan-v2.md](../execute-plan-v2.md). Contracts: [contracts.md](./contracts.md).
Runtime modules called here: [work-packages-runtime.md](./work-packages-runtime.md),
[work-packages-tick.md](./work-packages-tick.md). Kickoff prompts: [work-split-and-prompts.md](./work-split-and-prompts.md).

Workflow code rules: workflows are thin (checkout `main`, setup Node 22, run one script); all logic
lives in `scripts/lib/execute_plan_*.js` (protected, tested) with a small wrapper in
`.github/scripts/execute-plan-*.js`. No `npm ci`, no dependency, no `${{ github.event.* }}` inside
`run:` (pass values through `env`). The owner merges every PR of this file.

## Token table (B1, item 13)

| Operation | Token | Why |
|-----------|-------|-----|
| Reads | `GITHUB_TOKEN` | — |
| Create/update the `execute-plan-scope` **check run** | `GITHUB_TOKEN` | A PAT cannot create check runs, so the bot cannot forge it. |
| `workflow_dispatch` (Pre-UAT, Deploy UAT) | `GITHUB_TOKEN` | Dispatch events do start workflows. |
| Create branches, open sync/release PRs, `update-branch`, enable/disable auto-merge, merge | `EXECUTE_PLAN_BOT_TOKEN` | Must trigger CI and Pre-UAT (B1). |
| Issue comments, labels, status comment, closing the control issue | `EXECUTE_PLAN_BOT_TOKEN` | One identity edits the status comment (item 13). |
| Cursor API | `cursor_api_key` | — |

## WP6a — Cursor skills and commands

**Depends on:** WP5 · **Recommended executor:** Cursor · **Size:** docs only, ~150 changed lines

**Files (modify):** `.cursor/skills/execute-plan/SKILL.md`, `.cursor/commands/execute-plan.md`,
`.cursor/skills/babysit-plus/SKILL.md`, `.cursor/skills/babysit-uat/SKILL.md`.
**Do not touch:** `.claude/**`, `AGENTS.md`, any code.

1. `.cursor/skills/execute-plan/SKILL.md`: insert directly under the title a section
   `## v2 plans (snapshot schema_version 2)`, ≤ 20 lines: (a) planning session: write the plan
   file on `cursor/<plan_id>-init`, run `node scripts/execute_plan_runtime.js init <plan_id>`,
   end the session with the printed approval line; (b) worker session: run
   `node scripts/execute_plan_runtime.js tick <plan_id> --json --actor agent`, do the one `agent`
   action, run `tick` again, end the turn with one line when the actor is `driver` or `stop` is set;
   (c) the sentence "There is no stop table for v2: `tick` decides." Rename the rest of the file
   under `## v1 plans (schema 1)` without other changes except items 2–3.
2. Same file, v1 section: stop-table cell "CI/debt/merge failure" → "CI retry budget exhausted /
   debt-issue create failure / merge failure".
3. Same file: every relative link must resolve. The file is three levels below the repo root, so
   `../../AGENTS.md` → `../../../AGENTS.md`, `../../docs/…` → `../../../docs/…`,
   `../agent-kernel/…` → `../../agent-kernel/…`. Check each with `test -f`.
4. `.cursor/commands/execute-plan.md`: first line after the title: "v2 plans (`schema_version: 2`):
   see the skill's v2 section; the rules below apply to v1 plans."
5. `.cursor/skills/babysit-plus/SKILL.md`: in §Model (lines 62–64) and step 0b.1 (line 85) add:
   "During an active execute-plan (any schema), never switch model or spawn a fresh agent for this
   step; v2 workers never merge — the driver arms auto-merge." At §7 exit `2` (line ~188) replace
   "subscribe and **§Halt**" with "subscribe and wait for the lease holder; this is not a halt".
6. `.cursor/skills/babysit-uat/SKILL.md`: under the title: "v2 plans: merge, Pre-UAT watching and
   promotion are done by `tick` and the driver; use this skill's e2e-debug path only when `tick`
   returns a `remedial` action."

**Acceptance:** every relative link in `.cursor/skills/execute-plan/SKILL.md` resolves (list each link and its `test -f` result in the PR body);
`rg -n "§Halt" .cursor/skills/babysit-plus/SKILL.md | rg -i lease` prints nothing; `./scripts/pre-push-changed.sh` green.

## WP6b — Claude Code skill, AGENTS.md, memory, docs, link check

**Depends on:** WP5 · **Recommended executor:** Claude Code · **Size:** docs ~150 lines, optional hook ~80 code

**Files (modify):** `.claude/skills/execute-plan/SKILL.md`, `AGENTS.md`, `.agents/memory/execute-plan-autonomy.md`,
`.agents/memory/MEMORY.md`, `docs/agent-efficiency/autonomous-pr-policy.md`,
`docs/agent-efficiency/agent-instructions.md`, `scripts/validate_docs.sh`; optional item 7 adds
`.claude/settings.json`, `scripts/lib/execute_plan_stop_hook.js`, `scripts/test/execute_plan_stop_hook.test.js`.
**Do not touch:** `.cursor/**` (WP6a), runtime logic.

1. `.claude/skills/execute-plan/SKILL.md`: add the same v2 section as WP6a item 1 (Claude Code
   wording: use the Bash tool for `tick`; GitHub MCP tools for reads), keep the v1 pointer text.
2. `AGENTS.md` §Execute-plan (lines 58–66): prepend a 3-line v2 paragraph — "v2 plans: `tick`
   decides; workers do one agent action per launch and end the turn when the actor is `driver`;
   no chat rules apply. Spec: `docs/agent-efficiency/plans/execute-plan-v2.md`." Keep the v1 text.
3. `.agents/memory/execute-plan-autonomy.md`: fix its 3 links (`../AGENTS.md` → `../../AGENTS.md`,
   `../.cursor/…` → `../../.cursor/…`, `../docs/…` → `../../docs/…`) and add one line pointing to the v2 index.
4. `.agents/memory/MEMORY.md`: one bullet "Execute-plan v2 — liveness and integrity are mechanisms
   (tick, driver, scope check); never add prose stop rules" linking `../../docs/agent-efficiency/plans/execute-plan-v2.md`.
5. `docs/agent-efficiency/autonomous-pr-policy.md:86`: same merge-lease wording as WP6a item 5.
   `docs/agent-efficiency/agent-instructions.md`: add to its rules list "Execute-plan liveness or
   integrity failures are fixed with a mechanism, never with more instruction text."
6. Link check: in `scripts/validate_docs.sh:75-82` remove the `-not -path "*/.agents/*"` and
   `-not -path "*/.cursor/*"` exclusions, run `bash scripts/validate_docs.sh`, fix every broken
   link it reports. **Decision:** ≤ 30 broken links → fix them all in this PR; more than 30 → keep
   the two exclusions, add `.cursor/skills/` and `.agents/memory/` explicitly instead, and open a
   debt issue listing the rest.
7. Optional, last: Claude Code `Stop` hook. `.claude/settings.json` =
   `{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"node scripts/execute_plan_runtime.js stop-hook"}]}]}}`.
   `stop-hook` reads the hook JSON from stdin; exits `0` when `stop_hook_active` is true (loop guard)
   or the current branch is not a v2 plan branch (`cursor/<id>-p<n>`, `-sync-<n>`, `-remedial-<n>`);
   otherwise runs `tick --actor agent --json`; exits `2` with the handoff text on stderr when an
   `agent` action remains; else `0`. Tests: `non-plan branch exits 0`, `agent action exits 2`, `loop guard exits 0`.

**Acceptance:** `bash scripts/validate_docs.sh && ./scripts/pre-push-changed.sh`; with item 7,
`node --test scripts/test/execute_plan_stop_hook.test.js`.

## WP7a — Scope check, config, CI wiring

**Depends on:** WP2, WP3 · **Recommended executor:** Claude Code · **Size:** ~200 code, ~200 tests, ~40 YAML

**Files**
- Create: `.github/execute-plan.config.json` (contracts §3.8, `bot_login` from Phase 0),
  `scripts/lib/execute_plan_scope_run.js`, `scripts/lib/execute_plan_plans.js`,
  `.github/scripts/execute-plan-scope.js`, `.github/workflows/execute-plan-scope.yml`,
  `scripts/test/execute_plan_scope_run.test.js`.
- Modify: `.github/workflows/_reusable-test.yml` (governance job, after the
  `domain_coverage.fixture.mjs` step at line ~96), `scripts/execute_plan_runtime.js` (register `check-diff`).

**Do not touch:** `.github/workflows/agent-pr-safety-gate.yml` (stays until WP10), other workflows.

**Exports**
```js
// execute_plan_plans.js
function planIdFromRefs({ head_ref, base_ref })     // → candidate plan_id or null (patterns from WP2 categorizePull)
async function findControlIssue(client, planId)     // open issue labelled execute-plan + plan:<id>, else null
async function listActivePlans(client)              // open issues labelled execute-plan + autonomous-approved, without plan:complete
// execute_plan_scope_run.js
/** @returns {{ conclusion, title, summary, planId|null }} */
async function runScopeCheck(client, { prNumber, headSha, headRef, baseRef, headRepo, repo, now })
async function publishScopeCheck(client, { headSha, conclusion, title, summary }) // create or update the check run named execute-plan-scope
```

**`runScopeCheck` rules**
1. `headRepo !== repo` (fork) → `success`, title `ok`, summary `not an execute-plan PR (fork)`.
2. No plan id from the refs, or no open control issue → `success`, `ok`, `not an execute-plan PR`.
3. Load config from `main`, the status comment, `init_sha`, the snapshot at `init_sha` (WP3
   `loadSnapshotAtRef`; failure → `failure`, title `drift`, summary = the error).
4. `stopped` = `deriveControl` (WP4a) on observed control comments/labels/status → passed to `evaluateDiff`.
5. Files: `listPullFiles(prNumber)`; `PullFilesOverflow` → `failure`, title `too-many-files`.
6. `ownPlanFilesVerified` = when the diff contains the own plan files: their content at `headSha`
   (`getFileAtRef`) hashes to `approval_hash` (snapshot) and to `plan_file_sha256` (markdown).
7. Return `evaluateDiff` (WP2) output; `summary` lists violations and `companionsUsed`.

**`.github/workflows/execute-plan-scope.yml`**
```yaml
name: Execute-plan scope
on:
  pull_request_target:
    types: [opened, synchronize, reopened, ready_for_review, edited]
permissions:
  contents: read
  pull-requests: read
  issues: read
  checks: write
concurrency:
  group: execute-plan-scope-${{ github.event.pull_request.number }}
  cancel-in-progress: true
jobs:
  scope-runner:
    name: scope-runner
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v5
        with: { ref: main }          # trusted code only; PR code is never checked out
      - uses: actions/setup-node@v5
        with: { node-version: 22 }
      - name: Evaluate and publish execute-plan-scope
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PR_NUMBER: ${{ github.event.pull_request.number }}
          HEAD_SHA: ${{ github.event.pull_request.head.sha }}
          HEAD_REF: ${{ github.event.pull_request.head.ref }}
          BASE_REF: ${{ github.event.pull_request.base.ref }}
          HEAD_REPO: ${{ github.event.pull_request.head.repo.full_name }}
        run: node .github/scripts/execute-plan-scope.js
```
The job is named `scope-runner` so its own check run never shares the required check's name; the
script publishes the check run `execute-plan-scope` on `HEAD_SHA` and exits `0` either way.

**CI wiring** (`_reusable-test.yml`, governance job): new step `Execute-plan runtime tests` running
`node --test scripts/execute_plan_runtime.test.js scripts/test/execute_plan_*.test.js`.

**Tests:** `fork → success ok`, `non-plan PR → success ok`, `phase PR in scope → success`,
`phase PR unclassified → failure`, `drift on plan file edit`, `release PR with verified plan files → success`,
`overflow → too-many-files`, `stopped plan → plan-stopped`, `publish creates then updates the check run`
(all with the WP1 fake fetch).

**Acceptance:** `node --test scripts/test/execute_plan_scope_run.test.js && ./scripts/pre-push-changed.sh`;
actionlint: **decision** — if `actionlint -version` works locally, run
`actionlint .github/workflows/execute-plan-scope.yml .github/workflows/_reusable-test.yml`; otherwise
rely on the `actionlint.yml` workflow on the PR and do not mark ready until it is green.

**Docs:** `docs/pipelines/ci-cd-gates.md` — row for `execute-plan-scope` (what it checks, check run
from GitHub Actions, required on `main` and integration branches after WP8).

## WP7b — Approve and driver workflows

**Depends on:** WP4b, WP5, WP7a, WP7c · **Recommended executor:** Claude Code · **Size:** ~400 code, ~300 tests, ~90 YAML

**Files**
- Create: `scripts/lib/execute_plan_driver_actions.js`, `scripts/lib/execute_plan_approve.js`,
  `.github/scripts/execute-plan-approve.js`, `.github/scripts/execute-plan-driver.js`,
  `.github/workflows/execute-plan-approve.yml`, `.github/workflows/execute-plan-driver.yml`,
  `scripts/test/execute_plan_driver_actions.test.js`, `scripts/test/execute_plan_approve.test.js`.

**Do not touch:** `.github/scripts/execute-plan-launch.js` (WP7c; import only), other workflows.

**`execute_plan_approve.js` — `handleControlComment(clients, event, { now, killSwitch })`**
1. Kill switch `off` → return. `dry-run` → validate and write the job summary only.
2. Ignore comments on PRs and on issues without label `execute-plan`.
3. `approve`: read `Init branch: <name> @ <sha>` from the issue body; `loadSnapshotAtRef` at `<sha>`;
   `validateControlComment`; `compare(main...<sha>).files` must be exactly the two own plan files;
   the integration branch must not exist (exists at `<sha>` → idempotent success). Then, with the
   bot token: `createRef(refs/heads/<integration_branch>, <sha>)`; create the status comment
   (`init_sha`, `state: phase:pending`); labels `autonomous-approved`, `plan:<plan_id>`; append
   `Approval: valid (comment <id>)` to the issue body; run one driver pass for this plan.
4. Invalid approve → one comment `approve-autonomous rejected: <reason>`; nothing else.
5. `resume` (valid) → one driver pass. `revoke` (valid) → label `autonomous-revoked`, one driver pass.
6. `edited` / `deleted` of an approve or resume comment → one driver pass (`tick` stops with
   `approval-invalid` and the driver enforces it).

**`execute_plan_driver_actions.js` — `runDriverPass(clients, { planId, now, killSwitch })`**
1. `lease` = status `lease` present ? `{ ...status.lease, status: await getAgentRunStatus(...) }` : `null`.
2. `decision = await tick(botClient, { planId, actor: 'driver', lease, now, dryRun: killSwitch === 'dry-run' })`.
3. Execute `decision.action` (skipped in dry-run; logged in the job summary):
   `create-phase-branch` (bot, `createRef` at `from_sha`); `arm-auto-merge` (bot, GraphQL; if the
   error says the PR is in clean status → `mergePull` with the same method); `update-branch` (bot);
   `open-sync-pr` (bot, title `execute-plan sync: main → <integration>`, marker
   `<!-- execute-plan-sync:<id> -->`); `open-release-pr` (bot, title `Release: <title> (<plan_id>)`,
   body = phase table, `## Docs` listing every `docs/**` file in `compare(main...integration)` or
   `N/A — no documentation files changed in this release`, marker `<!-- execute-plan-release:<id> -->`);
   `dispatch-preuat` / `dispatch-deploy` (`GITHUB_TOKEN`, then record in `status.dispatched`);
   `enforce-stop` (for each open plan PR: `disableAutoMerge` with bot, `publishScopeCheck`
   `failure`/`plan-stopped` with `GITHUB_TOKEN`); `complete-plan` (WP5 `verifyComplete` path);
   agent action with `launch: true` → `launchPlanAgent` (WP7c) with `buildHandoffPrompt`, model
   `config.cursor_model_fix` for `fix-ci`/`fix-scope`/`triage-review`/`resolve-conflict`/`remedial`
   else `config.cursor_model_implement`, `startingRef` = the action's branch; then append to
   `status.launches` and set `status.lease` (bot).
4. One action per plan per pass; the next event or heartbeat continues.

**`.github/scripts/execute-plan-driver.js` — `plansForEvent`:** `pull_request` /
`pull_request_review` → plan from the PR refs (`planIdFromRefs`); `workflow_run` of `CI` → the
plans of `workflow_run.pull_requests[]` (all active plans when empty); other `workflow_run`,
`schedule`, `workflow_dispatch` without `plan_id` → `listActivePlans`; `workflow_dispatch` with
`plan_id` → that plan; `issues` → the plan from the issue's `plan:<id>` label. Fork PRs are ignored.

**`.github/workflows/execute-plan-approve.yml`**
```yaml
name: Execute-plan approve
on:
  issue_comment:
    types: [created, edited, deleted]
permissions:
  contents: read
  issues: write
  pull-requests: write
  actions: write
  checks: write
concurrency:
  group: execute-plan-approve-${{ github.event.issue.number }}
  cancel-in-progress: false
jobs:
  approve:
    name: execute-plan-approve
    if: >-
      github.event.issue.pull_request == null &&
      github.event.comment.author_association == 'OWNER' &&
      (startsWith(github.event.comment.body, 'approve-autonomous ') ||
       startsWith(github.event.comment.body, 'resume-autonomous ') ||
       startsWith(github.event.comment.body, 'revoke-autonomous '))
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v5
        with: { ref: main }
      - uses: actions/setup-node@v5
        with: { node-version: 22 }
      - name: Handle control comment
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          EXECUTE_PLAN_BOT_TOKEN: ${{ secrets.EXECUTE_PLAN_BOT_TOKEN }}
          CURSOR_API_KEY: ${{ secrets.cursor_api_key }}
          EXECUTE_PLAN_DRIVER: ${{ vars.EXECUTE_PLAN_DRIVER }}
          EVENT_PATH: ${{ github.event_path }}
        run: node .github/scripts/execute-plan-approve.js
```
`tick` re-validates the authorizing comment on every pass, so an edit that changes the comment
prefix (and therefore skips this workflow) is still caught by the next driver pass.

**`.github/workflows/execute-plan-driver.yml`**
```yaml
name: Execute-plan driver
on:
  schedule:
    - cron: '*/30 * * * *'
  workflow_dispatch:
    inputs:
      plan_id: { description: Plan id (empty = all active), required: false }
  pull_request:
    types: [opened, ready_for_review, converted_to_draft, synchronize, closed]
  pull_request_review:
    types: [submitted]
  workflow_run:
    workflows: ['CI', 'Pre-UAT E2E', 'Promote UAT (tag on merge to main)', 'Deploy UAT (uat.agathatrack.com)']
    types: [completed]
  issues:
    types: [labeled, unlabeled]
permissions:
  contents: read
  issues: write
  pull-requests: write
  actions: write
  checks: write
concurrency:
  group: execute-plan-driver
  cancel-in-progress: false
jobs:
  drive:
    name: execute-plan-driver
    if: github.event.pull_request == null || github.event.pull_request.head.repo.full_name == github.repository
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v5
        with: { ref: main }
      - uses: actions/setup-node@v5
        with: { node-version: 22 }
      - name: Drive active plans
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          EXECUTE_PLAN_BOT_TOKEN: ${{ secrets.EXECUTE_PLAN_BOT_TOKEN }}
          CURSOR_API_KEY: ${{ secrets.cursor_api_key }}
          EXECUTE_PLAN_DRIVER: ${{ vars.EXECUTE_PLAN_DRIVER }}
          EVENT_NAME: ${{ github.event_name }}
          EVENT_PATH: ${{ github.event_path }}
          INPUT_PLAN_ID: ${{ inputs.plan_id }}
        run: node .github/scripts/execute-plan-driver.js
```
Notes: `check_suite` is not used — GitHub does not start workflows from check suites created by
GitHub Actions, so CI completion comes from `workflow_run` of `CI` (`ci.yml` `name: CI`).
`workflow_run` chains stop at three levels (Pre-UAT → Promote → Deploy → driver would be the
fourth), so driver runs after Deploy UAT may not fire; the 30-minute heartbeat covers them and
correctness never depends on those events. One global concurrency group is accepted for v1
(Fable's disagreement); the driver never waits inside a job (no watchers).

**Tests:** approve `valid → branch + status + labels + driver pass`, `not owner → ignored`,
`invalid hash → rejected comment`, `init branch with extra files → rejected`, `resume → driver pass`,
`revoke → label + driver pass`, `kill switch off → no-op`, `dry-run → no writes`; driver
`plansForEvent per event type`, `fork PR ignored`, `arm-auto-merge clean status falls back to merge`,
`enforce-stop disables auto-merge and publishes plan-stopped`, `launch records lease and launches`,
`lease alive → no launch`, `dispatch-preuat recorded once per head`.

**Acceptance:** `node --test scripts/test/execute_plan_driver_actions.test.js scripts/test/execute_plan_approve.test.js && ./scripts/pre-push-changed.sh`;
actionlint decision as in WP7a.

**Docs:** `docs/agent-efficiency/github-issue-workflow.md` — section "Execute-plan v2 driver"
(events, token table, kill switch, approve/resume/revoke comments).

**Owner hand-off:** merge; create secret `EXECUTE_PLAN_BOT_TOKEN` (runbooks §7.1); set variable
`EXECUTE_PLAN_DRIVER=dry-run`; check that the next scheduled driver run shows a job summary and no writes.

## WP7c — Cursor launch adapter (Cursor-specific)

**Depends on:** nothing (run in parallel with WP1–WP3) · **Recommended executor:** Cursor · **Size:** ~120 code, ~120 tests

**Files (create):** `.github/scripts/execute-plan-launch.js`, `scripts/test/execute_plan_launch.test.js` (under `scripts/test/` so the CI glob from WP7a runs it).
**Do not touch:** `.github/scripts/launch-cursor-agent.js`, `.github/scripts/monitor-cursor-agent.js` (read them; reuse their request shape).

**Exports**
```js
/** @returns {Promise<{ agentId: string, runId: string, agentUrl: string|null }>} */
async function launchPlanAgent({ apiKey, repoUrl, startingRef, prompt, model, fetchImpl })
/** @returns {Promise<'CREATING'|'RUNNING'|'FINISHED'|'ERROR'|'CANCELLED'|'EXPIRED'|'UNKNOWN'>} */
async function getAgentRunStatus({ apiKey, agentId, runId, fetchImpl })
```

**Rules**
1. Request shape copied from `.github/scripts/launch-cursor-agent.js:46-60`: `POST https://api.cursor.com/v1/agents`
   with `prompt.text`, `repos: [{ url, startingRef }]`, `autoCreatePR: false`, `model: { id }`;
   the response fields `agent.id`, `run.id`, `agent.url` (`launch-cursor-agent.js:135-137`).
2. Status: `GET /v1/agents/{agentId}/runs/{runId}` → `status` (as `monitor-cursor-agent.js:185`);
   any error → `UNKNOWN` (never throw from the status call).
3. **VERIFY (Cursor API docs, decision):** does `workOnCurrentBranch: true` with `startingRef = <branch>`
   make the agent commit and push to that existing branch? Yes → send `workOnCurrentBranch: true`.
   No or unclear → send `false` and append to the prompt: "Commit to branch `<branch>`; push with
   `git push origin HEAD:<branch>`; never create another branch." Record the answer in the PR body.
4. **VERIFY (Cursor dashboard, decision):** a Cloud Agent launched through the API receives the
   cloud secret `GH_TOKEN`. Yes → nothing to do. No → stop and report; the owner must configure it
   (runbooks §7.1 step 5) before WP8.

**Tests:** `launch request body matches the contract`, `launch returns ids from the response`,
`status maps RUNNING`, `status error → UNKNOWN` (fake fetch).

**Acceptance:** `node --test scripts/test/execute_plan_launch.test.js`; add the file to the governance block of `scripts/pre-push-changed.sh`.

## WP8 — Rulesets and live verification

**Depends on:** WP7b merged, identity in place (runbooks §7.1), driver in `dry-run` · **Recommended executor:** Cursor (its `GH_TOKEN` is the bot, which some checks need) with the owner

Each step is a decision; on any unexpected outcome, stop and report.
1. **Check placement.** Open a probe PR with the bot token from `cursor/execute-plan-v2-probe-<4>`
   (one whitespace change in `docs/agent-efficiency/plans/README.md`) into `main`.
   Expected: a check run named `execute-plan-scope`, app `github-actions`, conclusion `success`,
   title `ok`. Seen → continue. Not seen → stop and report the workflow run link.
2. **Unattributed-changes rule.** On the same probe PR, with every check green, read
   `GET /pulls/{n}` → `mergeable_state`. `clean` → continue. `blocked` → report; the owner sets
   `require_extra_approval_for_unattributed_changes: false` on the `main` ruleset (runbooks §7.2),
   then re-check. Close the probe PR without merging.
3. **Owner** applies runbooks §7.2 (both rulesets, contexts pinned to `integration_id: 15368`) and §7.3.
4. **Sandbox plan** `scope-probe-0000` (init on `cursor/scope-probe-0000-init`, approved by the owner
   with a 1-day window, `EXECUTE_PLAN_DRIVER=on` for the duration). Fixture PRs and expected results:
   (a) out-of-scope file → `execute-plan-scope` red `unclassified`; (b) snapshot edit → red `drift`
   and the control issue gets `needs-owner`; (c) push of `.github/workflows/x.yml` with the bot
   token → rejected by GitHub (no `workflow` scope); (d) `docs/architecture/openapi/*.json`
   companion → green, companion listed; (e) non-plan PR → green; (f) the bot posts a commit status
   `execute-plan-scope = success` on PR (a)'s head → PR (a) still blocked. Record PR numbers on the
   control issue, comment `revoke-autonomous scope-probe-0000`, delete the branches, set
   `EXECUTE_PLAN_DRIVER=dry-run` again.
5. **Owner** sets `EXECUTE_PLAN_DRIVER=on` when WP9 starts.

**Acceptance:** the six fixture outcomes recorded on the sandbox control issue; both rulesets active
(`Main protection`, `Execute-plan integration`).
