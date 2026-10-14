---
title: Execute-plan v2 — platform work packages (WP6–WP8) and workflows
owner: Kanopee
audience: agent
status: active
last_updated: 2026-10-15
tags: [agent, execute-plan, autonomy, github-actions]
---
# Execute-plan v2 — platform work packages (WP6–WP8) and workflows

Part of [execute-plan-v2.md](../execute-plan-v2.md). Contracts: [contracts.md](./contracts.md).
Runtime modules these packages call: [work-packages-runtime.md](./work-packages-runtime.md).
The executor never merges a PR touching `.github/**` and never applies rulesets (owner hand-off).

## WP6 — Skills and rules (Cursor + Claude Code)

**Branch:** `claude/execute-plan-v2-wp6` · **Size:** docs only, ~250 changed lines · **Depends on:** WP4, WP5 merged

**Files and changes**
1. `.cursor/skills/execute-plan/SKILL.md` and `.claude/skills/execute-plan/SKILL.md` — new top section **"v2 plans (`schema_version: 2`)"**, ≤ 20 lines:
   `init` (one human checkpoint) → after approval the driver launches workers → a worker runs
   `node scripts/execute_plan_runtime.js tick <plan_id> --json --actor agent`, performs the one
   `agent` action, runs `tick` again, and ends its turn when the actor is `driver` or `stop` is set.
   Then the sentence: *"There is no stop table: `tick` decides."* Keep the existing v1 text below a
   `## v1 plans (schema 1)` heading, unchanged except items 2–3 below (B8).
2. Same two files, v1 section: stop table entry "CI/debt/merge failure" → "CI retry budget
   exhausted"; fix the relative links (10 of 11 resolve one folder too shallow — e.g.
   `../../AGENTS.md` → `../../../AGENTS.md`; verify each with `test -f`).
3. `.cursor/skills/babysit-plus/SKILL.md` — at §Model (lines 62–64, 85): add "Active execute-plan
   (any schema): do not switch model or spawn a fresh agent; v2 workers never merge — `tick` arms
   auto-merge." At the merge-lease exit `2` line (~188): "wait with subscription; not a halt."
4. `docs/agent-efficiency/autonomous-pr-policy.md:86` — same lease wording; `:51` unchanged;
   `:313` already changed in WP3.
5. `.cursor/skills/babysit-uat/SKILL.md` — line 8 area: "v2 plans: Phases 1–4 of this skill are
   performed by `tick`/auto-merge; use §Phase 3 (e2e-debug) when `tick` returns `remedial`."
6. `AGENTS.md:58-66` §Execute-plan → v2 paragraph (3 lines: gate is `tick`; workers do one action
   per launch; no chat rules) + "v1 plans: see the skill's v1 section".
7. `.agents/memory/execute-plan-autonomy.md` — fix its 3 links; content becomes a pointer to the
   v2 index and the v1 skill section.
8. `.agents/memory/MEMORY.md` — one index bullet titled "Execute-plan v2", linking (relative to
   `.agents/memory/`) to `docs/agent-efficiency/plans/execute-plan-v2.md`, hook text: "liveness and
   integrity are mechanisms (tick, driver, scope check); never add prose stop rules."
9. `docs/agent-efficiency/agent-instructions.md` (**VERIFY** path: `rg -l "agent-instructions" docs | head -3`) — meta-rule: "Execute-plan liveness/integrity failures are fixed with a mechanism, never with more text."
10. Link validation — extend the docs link check to `.cursor/**/*.md` and `.agents/**/*.md`
    (**VERIFY** the checker: `rg -n "link" scripts/validate_docs.sh | head`); fix what it finds.
11. Plan-file rule: `scripts/validate_execute_plan_snapshot.js` (v2 path from WP3) rejects
    `## Contract` / `## Rules` headings — confirm the error message is documented in
    `docs/agent-efficiency/plan-template.md`.
12. Optional, last (R10): `.claude/settings.json` Stop hook →
    `{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"node scripts/execute_plan_runtime.js stop-hook"}]}]}}`
    with a new `stop-hook` subcommand: reads hook JSON from stdin; exits `0` immediately when
    `stop_hook_active` is true (loop guard) or the current branch is not a v2 plan branch; else
    runs `tick --actor agent`; exits `2` with the handoff text on stderr when an `agent` action
    remains; exits `0` otherwise. Test: `stop-hook exits 0 on non-plan branch`,
    `stop-hook exits 2 with action`, `stop-hook loop guard`.

**Acceptance:** `bash scripts/validate_docs.sh && ./scripts/pre-push-changed.sh`; a grep proves no
contradiction remains: `rg -n "§Halt" .cursor/skills/babysit-plus/SKILL.md docs/agent-efficiency/autonomous-pr-policy.md | rg -i lease` returns nothing.

**Kickoff prompt:** "Implement WP6 of docs/agent-efficiency/plans/execute-plan-v2.md (index, work-packages-platform.md WP6). Docs/skills only; v1 text preserved; fix links and contradictions; optional Stop hook last. Draft PR, ready when docs gates are green."

## WP7 — Workflow scripts and the three workflows

**Branch:** `claude/execute-plan-v2-wp7` · **Size:** ~500 lines scripts, ~300 lines tests, ~150 lines YAML · **Depends on:** WP1–WP5 merged · **Owner merges this PR.**

**Files**
- `.github/execute-plan.config.json` (new, on `main`): `{ "owners": ["KanopeeKa"], "bot_login": "<machine user>", "cursor_model_implement": "<per model policy>", "cursor_model_fix": "composer-2.5" }`.
- `.github/scripts/execute-plan-lib.js` — `loadConfig()`, `plansForEvent(event)`, `killSwitch()`, `tokens()`.
- `.github/scripts/execute-plan-approve.js`, `execute-plan-driver.js`, `execute-plan-scope.js`, `execute-plan-launch.js` + `*.test.js` for each (node:test, fixtures from `scripts/test/fixtures/execute-plan-v2/`). **VERIFY** how `.github/scripts/*.test.js` run today: `rg -n "github/scripts" scripts/pre-push.sh scripts/pre-push-changed.sh .github/workflows/ci.yml`; add the new tests the same way.
- `.github/workflows/execute-plan-approve.yml`, `execute-plan-driver.yml`, `execute-plan-scope.yml` (YAML below).

**Token table (B1)**

| Operation | Token |
|-----------|-------|
| Reads, labels, issue comments, check-run/status publication, `workflow_dispatch`, `rerunFailedJobs` | `GITHUB_TOKEN` |
| Create integration branch, open sync/release PRs, `update-branch`, enable/disable auto-merge, `merge-now` | `EXECUTE_PLAN_BOT_TOKEN` (machine user) |
| Cursor API | `cursor_api_key` |

`execute-plan-scope.yml` receives **no secrets** and only `GITHUB_TOKEN`.

**`execute-plan-approve.js` rules**
1. Kill switch `off` → exit 0 with a notice. `dry-run` → verify and report, no label, no launch.
2. Only issues (not PRs) labelled `execute-plan`. Parse `approve-autonomous` / `revoke-autonomous` (contracts §3.3).
3. Approval: locate the init branch head from the issue body (`Init branch: <name> @ <sha>`), load the snapshot and plan file at that SHA, `validateApproval` (WP3) against the comment; check `compare(main...<sha>).files` ⊆ `.agents/plans/<plan_id>.*` (init branch is plan-files-only).
4. On success: create `refs/heads/<integration_branch>` at that SHA with the bot token; add labels `autonomous-approved`, `plan:<plan_id>`; edit the issue body `Approval: valid (comment <id>)`; then run the driver logic once for this plan (first `implement` launch).
5. On failure: one comment `approve-autonomous rejected: <reason>` and no label. `edited`/`deleted` on an approval comment → run `tick` (it returns STOP `approval-invalid`) and disable auto-merge.
6. Revocation → label `autonomous-revoked`, `tick` (STOP `revoked`), disable auto-merge on open plan PRs.

**`execute-plan-driver.js` rules**
1. Kill switch: `off` → exit 0; `dry-run` → `tick --dry-run`, log the action, never launch or write.
2. Ignore events from fork PRs (`pull_request.head.repo.full_name !== repository`).
3. `plansForEvent`: PR events → plan whose branches match head/base; `check_suite` → its PRs → plans; `workflow_run` / `schedule` / `workflow_dispatch(no plan_id)` → every open issue with labels `execute-plan` + `autonomous-approved`; `issues`/`issue_comment` → that issue's plan.
4. For each plan: `tick(client, { actor: 'driver' })`. `driver` actions are executed here with the bot token; `agent` actions with `launch: true` → `launchPlanAgent`, then `recordLaunch`. `wait` and `stop` → nothing more.
5. `launchPlanAgent({ repoUrl, startingRef, branchName, promptText, model })` (R1): new function in `execute-plan-launch.js` mirroring the request of `.github/scripts/launch-cursor-agent.js:46-60` with `autoCreatePr: false` and the plan branch as source ref (**VERIFY** exact field names in that file before coding); prompt = contracts §3.6 handoff; model from config by action kind (`fix-ci`/`triage-review`/`remedial` → `cursor_model_fix`, else `cursor_model_implement`). Returns `{ agentId }`.
6. Never post comments except through `tick`. Job summary lists plan, state, action, launch id.

**`execute-plan-scope.js` rules**
1. Inputs from `env` only (`PR_NUMBER`, `HEAD_SHA`, `HEAD_REF`, `BASE_REF`, `HEAD_REPO`), never interpolated into `run:` (B5).
2. Resolve plan by branch patterns against open `execute-plan` issues (snapshot read from the integration branch; for `sync`/`release`/`remedial` PRs the integration branch comes from the plan whose id prefix matches the head ref). Non-plan PR or fork PR → **success** with summary `not an execute-plan PR`.
3. Plan PR → `evaluateDiff` (WP2) with `controlState` from the control issue; paginate `listPullFiles`; overflow → **failure** `too many files`.
4. Publish: `--mode check` creates/updates a check run named `execute-plan-scope` on `HEAD_SHA` (`checks: write`); `--mode status` publishes a commit status with context `execute-plan-scope`. Default `check`; WP8 decides after the B5 VERIFY.
5. Red for `drift`/`protected` additionally comments nothing; `tick` turns it into STOP `drift`. Red for `unclassified`/companion cap → `tick` action `fix-scope` (agent; counts as a CI attempt).

**YAML — `.github/workflows/execute-plan-approve.yml`**
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
concurrency:
  group: execute-plan-approve-${{ github.event.issue.number }}
  cancel-in-progress: false
jobs:
  approve:
    name: execute-plan-approve
    if: >-
      github.event.issue.pull_request == null &&
      (startsWith(github.event.comment.body, 'approve-autonomous ') || startsWith(github.event.comment.body, 'revoke-autonomous '))
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
        with: { ref: main }
      - uses: actions/setup-node@v5
        with: { node-version: 22 }
      - name: Verify approval and start the plan
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          EXECUTE_PLAN_BOT_TOKEN: ${{ secrets.EXECUTE_PLAN_BOT_TOKEN }}
          CURSOR_API_KEY: ${{ secrets.cursor_api_key }}
          EXECUTE_PLAN_DRIVER: ${{ vars.EXECUTE_PLAN_DRIVER }}
          EVENT_PATH: ${{ github.event_path }}
        run: node .github/scripts/execute-plan-approve.js
```

**YAML — `.github/workflows/execute-plan-driver.yml`**
```yaml
name: Execute-plan driver
on:
  schedule:
    - cron: '*/30 * * * *'
  workflow_dispatch:
    inputs:
      plan_id: { description: Plan id (empty = all active), required: false }
      dry_run: { description: Observe only, type: boolean, default: false }
  pull_request:
    types: [opened, ready_for_review, converted_to_draft, synchronize, closed]
  pull_request_review:
    types: [submitted]
  check_suite:
    types: [completed]
  workflow_run:
    workflows: ['Pre-UAT E2E', 'Promote UAT (tag on merge to main)', 'Deploy UAT (uat.agathatrack.com)', 'UAT Live E2E']
    types: [completed]
  issues:
    types: [labeled, unlabeled]
permissions:
  contents: read
  issues: write
  pull-requests: write
  actions: write
  checks: read
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
      - name: Tick active plans
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          EXECUTE_PLAN_BOT_TOKEN: ${{ secrets.EXECUTE_PLAN_BOT_TOKEN }}
          CURSOR_API_KEY: ${{ secrets.cursor_api_key }}
          EXECUTE_PLAN_DRIVER: ${{ vars.EXECUTE_PLAN_DRIVER }}
          EVENT_NAME: ${{ github.event_name }}
          EVENT_PATH: ${{ github.event_path }}
          INPUT_PLAN_ID: ${{ inputs.plan_id }}
          INPUT_DRY_RUN: ${{ inputs.dry_run }}
        run: node .github/scripts/execute-plan-driver.js
```
Disagreement with R5 noted: one global concurrency group instead of per plan, because `plan_id`
is unknown at workflow level for `schedule`/`workflow_run` events; the script loops over plans.
Per-plan grouping is an optimisation for when plans run concurrently.

**YAML — `.github/workflows/execute-plan-scope.yml`**
```yaml
name: Execute-plan scope
on:
  pull_request_target:
    types: [opened, synchronize, reopened, ready_for_review]
permissions:
  contents: read
  pull-requests: read
  checks: write
  statuses: write
concurrency:
  group: execute-plan-scope-${{ github.event.pull_request.number }}
  cancel-in-progress: true
jobs:
  scope:
    name: execute-plan-scope
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v5
        with: { ref: main }          # trusted code only; PR code is never checked out
      - uses: actions/setup-node@v5
        with: { node-version: 22 }
      - name: Evaluate plan scope
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PR_NUMBER: ${{ github.event.pull_request.number }}
          HEAD_SHA: ${{ github.event.pull_request.head.sha }}
          HEAD_REF: ${{ github.event.pull_request.head.ref }}
          BASE_REF: ${{ github.event.pull_request.base.ref }}
          HEAD_REPO: ${{ github.event.pull_request.head.repo.full_name }}
        run: node .github/scripts/execute-plan-scope.js --mode check
```

**Tests:** approve `valid → labels + branch + launch`, `not owner → rejected`, `edited → stop`,
`revoke → disable auto-merge`, `kill switch off → no-op`, `dry-run → no writes`; driver
`plansForEvent per event type`, `fork PR ignored`, `driver action executed with bot token`,
`agent action launches once and records`, `lease alive → no launch`; scope `non-plan → success`,
`fork → success`, `phase red unclassified`, `drift red`, `overflow red`, `stopped plan red`; launch
`request body matches recorded fixture`.

**Acceptance:** `node --test .github/scripts/execute-plan-*.test.js && actionlint .github/workflows/execute-plan-*.yml && ./scripts/pre-push-changed.sh` (**VERIFY** `actionlint` availability: `actionlint -version || echo "run via .github/workflows/actionlint.yml"`).

**Docs:** `docs/agent-efficiency/github-issue-workflow.md` § Execute-plan v2 driver (events, tokens, kill switch); `docs/pipelines/ci-cd-gates.md` row for `execute-plan-scope`.

**Owner hand-off after this WP:** merge the PR; create secret `EXECUTE_PLAN_BOT_TOKEN`; set variable `EXECUTE_PLAN_DRIVER=dry-run`; confirm the driver's scheduled run shows a job summary with no writes.

**Kickoff prompt:** "Implement WP7 of docs/agent-efficiency/plans/execute-plan-v2.md (index, contracts.md, work-packages-platform.md WP7). Thin workflows, logic in .github/scripts with node:test. Do not merge; mark ready and hand off to the owner."

## WP8 — Scope check wiring, rulesets, verification

**Branch:** none for code; owner applies settings per [runbooks §7.2–7.4](./runbooks-proof-retirement.md) · **Executor part:** verification only · **Depends on:** WP7 merged, identity in place

1. **VERIFY (B5)** check placement: open a throwaway PR from branch `claude/execute-plan-v2-scope-probe` (one whitespace change in `docs/agent-efficiency/README.md`) into `main`; confirm a check named `execute-plan-scope` appears on the PR head with conclusion `success`. If it does not appear, switch the workflow step to `--mode status` and confirm a commit status with that context appears. Close the probe PR without merging.
2. Owner adds `execute-plan-scope` to the `main` ruleset required checks and creates the integration ruleset (§7.2); enables auto-merge (§7.3).
3. Fixture verification on a sandbox v2 plan `scope-probe-0000` (init on branch `cursor/scope-probe-0000-init`, approved by the owner with a 1-day window): PRs (a) out-of-scope file → red `unclassified`; (b) snapshot edit → red `drift` and `tick` STOP; (c) `.github/workflows/x.yml` edit → red `protected` **and** GitHub rejects the push when done with the bot token (no `workflow` scope); (d) companion `openapi/*.json` → green with the companion logged; (e) non-plan PR → green. Record the PR numbers in the control issue, then `revoke-autonomous scope-probe-0000` and delete its branches.
4. Owner sets `EXECUTE_PLAN_DRIVER=on`.

**Acceptance:** the five fixture outcomes recorded on the sandbox control issue; the probe PR closed; both rulesets active (`gh api repos/KanopeeKa/AgathaCheck/rulesets --jq '.[] | select(.enforcement=="active") | .name'` lists `Main protection` and `Execute-plan integration`).

**Kickoff prompt:** "Run WP8 of docs/agent-efficiency/plans/execute-plan-v2.md (work-packages-platform.md WP8 + runbooks §7.2–7.4). Verification only; stop at each owner step and report."
