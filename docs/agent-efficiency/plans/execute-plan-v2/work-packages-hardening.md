---
title: Execute-plan v2 — worker identity hardening (WP11–WP12)
owner: Kanopee
audience: both
status: active
last_updated: 2026-11-02
tags: [agent, execute-plan, autonomy, security]
---
# Execute-plan v2 — worker identity hardening (WP11–WP12)

Part of [execute-plan-v2.md](../execute-plan-v2.md). Two work packages and one owner step that
tighten who can act in an execute-plan run. Self-contained: executors never need the conversation
that produced this file. Facts are cited as `path:line` on `main` @ `6f28bf6f`.

## Goal

1. **Least privilege for agents the automation launches.** Plan workers and issue/dispatch agents
   run with the bot identity only. No owner credential is available to them, and a worker `tick`
   refuses to run when one is present.
2. **Authorizations come from the owner, confirmed by trusted code.** An `approve-autonomous` or
   `resume-autonomous` comment counts only after the approve workflow (trusted `main` code in
   Actions) has confirmed it at the moment it was posted, while no plan worker was running.

Non-goals: changing `/runasme` (owner opt-in per message stays as it is), changing the worker loop,
budgets, the scope check, or the bot identity. `OWNER_GH_TOKEN` stays in the Cursor dashboard.

## Order

| Step | Who | Depends on | Outcome |
|------|-----|------------|---------|
| WP11 | Cursor (Composer 2.5) | — | Launches blank owner credentials; worker `tick` refuses with one |
| Owner probe | Owner | WP11 merged | Confirms the blank value overrides the dashboard secret |
| WP12 | Cursor (Composer 2.5) | WP11 merged, probe done, **no active plan** | Authorizations need a trusted acknowledgement |

Ground rules: [execute-plan-v2.md §2](../execute-plan-v2.md#2-executor-ground-rules) apply to both
WPs (plan-first draft PR, `./scripts/pre-push-changed.sh` before every push, files ≤ 500 lines,
Node 22 built-ins only, offline tests, **never merge** — the owner merges and reads every
`.github/**` diff). These are ordinary PRs into `main`, **not** an execute-plan run: every file
below is in the protected set (`scripts/lib/execute_plan_scope.js:13-33`), so a plan PR could not
change them.

---

## WP11 — No owner credential in launched agents

**Branch:** `cursor/execute-plan-v2-wp11-<4 lowercase letters or digits>` · **PR title:**
`security: execute-plan workers and dispatched agents never hold the owner token (WP11)`

### Code

1. `.github/scripts/execute-plan-launch.js` — add and export
   `workerLaunchEnvVars(botToken)`:
   - returns `{ GH_TOKEN: botToken, EXECUTE_PLAN_TOKEN: botToken, OWNER_GH_TOKEN: '', BOT_GH_TOKEN: '' }`
     when `botToken` is a non-blank string;
   - returns `{ OWNER_GH_TOKEN: '', BOT_GH_TOKEN: '' }` otherwise (the agent then uses the
     dashboard `GH_TOKEN`, which is the bot).
   - Export the blanked key list as `BLANKED_LAUNCH_KEYS = Object.freeze(['OWNER_GH_TOKEN', 'BOT_GH_TOKEN'])`.
2. `scripts/lib/execute_plan_driver_actions.js:180` — replace the inline object with
   `workerLaunchEnvVars(botToken)` (import from the file above; `defaultDeps` at `:37` already
   requires it).
3. `.github/scripts/launch-cursor-agent.js` — `botLaunchEnvVars(env)` (`:52-57`) returns
   `workerLaunchEnvVars(env.EXECUTE_PLAN_BOT_TOKEN)`, so it never returns `undefined` any more.
   `launchAgent` (`:59-77`) then always sends `envVars`.
4. `scripts/lib/execute_plan_tick.js` — `tick(client, { …, env = process.env })` (`:64`). When
   `actor === 'agent'`, **before** `loadPlanContext`, throw `configError(OWNER_TOKEN_MESSAGE(planId))`
   if `String(env.OWNER_GH_TOKEN || '').trim() !== ''`. Exit code 3 comes from `configError`
   (`scripts/lib/execute_plan_observe.js:20-22`); nothing is read or written first. Message (exact,
   never includes the value):
   ```
   OWNER_GH_TOKEN is set: execute-plan workers must not hold the owner token. Run tick as:
   env -u OWNER_GH_TOKEN -u BOT_GH_TOKEN node scripts/execute_plan_runtime.js tick <plan_id> --json --actor agent
   ```
   `--actor driver` is unchanged (the driver runs in Actions with no dashboard secrets).
5. `scripts/lib/execute_plan_driver_actions.js:74` — the handoff prompt's tick line becomes
   `` `env -u OWNER_GH_TOKEN -u BOT_GH_TOKEN node scripts/execute_plan_runtime.js tick ${id} --json --actor agent` ``.

### Instructions and docs (same PR)

Replace the worker tick command with the `env -u OWNER_GH_TOKEN -u BOT_GH_TOKEN …` form in:
`AGENTS.md` §Execute-plan (`:60`), `.cursor/skills/execute-plan/SKILL.md` §Worker session,
`.claude/skills/execute-plan/SKILL.md` (`:10`), `docs/agent-efficiency/execute-plan-instruction-stack.md:19`,
`docs/agent-efficiency/plans/execute-plan-v2/contracts.md` §3.6 (keep it identical to step 5). Add
one sentence to each skill: "Each command may run in a fresh shell, so prefix every `tick` with
`env -u`; `unset` does not carry over."

- `.cursor/skills/run-as-me/SKILL.md` — after step 5, add a **Never in owner mode** line: posting
  `approve-autonomous` / `resume-autonomous` comments, and
  removing the `needs-owner` or `autonomous-revoked` labels (the owner does these in the GitHub web
  interface). Revoking stays allowed. Step 6 adds: "`tick` refuses to run while `OWNER_GH_TOKEN` is set."
- `.cursor/skills/cloud-github-identity/SKILL.md` and `docs/engineering/cursor-cloud-environment.md` —
  one line each: agents launched by the driver or by issue/dispatch get `OWNER_GH_TOKEN` and
  `BOT_GH_TOKEN` blanked through launch `envVars`; owner mode is for interactive sessions only.
- `docs/agent-efficiency/plans/execute-plan-v2/runbooks-proof-retirement.md` §7.1 step 5 — the
  plan-worker sentence lists the blanked keys.
- `docs/agent-efficiency/plans/execute-plan-v2.md` — decision-log row "WP11 (planned)" → shipped
  wording with the PR number.

### Tests (offline; extend existing files, no new test file)

- `scripts/test/execute_plan_driver_actions.test.js:241-247` — `envVars` deep-equals
  `{ GH_TOKEN, EXECUTE_PLAN_TOKEN, OWNER_GH_TOKEN: '', BOT_GH_TOKEN: '' }`; the token is still never logged.
- `scripts/test/launch_cursor_agent_bot_env.test.js` — with a bot token: the four keys; without
  (missing or blank): exactly `{ OWNER_GH_TOKEN: '', BOT_GH_TOKEN: '' }`.
- `scripts/test/execute_plan_launch.test.js` — `workerLaunchEnvVars` both branches; `BLANKED_LAUNCH_KEYS`.
- `scripts/test/execute_plan_tick.test.js` — `actor: 'agent'` with `env: { OWNER_GH_TOKEN: 'x' }`:
  rejects with `exitCode === 3`, the message contains `env -u OWNER_GH_TOKEN` and not `x`'s value
  (use a distinctive value such as `owner-secret-value`), and the fake client recorded **zero**
  calls. `env: { OWNER_GH_TOKEN: '  ' }` and `env: {}` proceed. `actor: 'driver'` with the variable
  set proceeds. Existing identity tests (`assertWorkerIsBot`) unchanged and green.

### Acceptance

```bash
node --test scripts/execute_plan_runtime.test.js scripts/test/execute_plan_*.test.js scripts/test/launch_cursor_agent_bot_env.test.js
node scripts/check_docs_canonical.js --instructions
bash scripts/validate_docs.sh
./scripts/pre-push-changed.sh
rg -n "execute_plan_runtime.js tick <plan_id> --json --actor agent" AGENTS.md .cursor/skills .claude/skills docs/agent-efficiency/execute-plan-instruction-stack.md docs/agent-efficiency/plans/execute-plan-v2/contracts.md
```

The last command prints only lines that start with the `env -u` prefix.

---

## Owner probe — blank value overrides the dashboard secret

After WP11 merges, before the next plan. Run locally on `main` with your Cursor API key:

```bash
CURSOR_API_KEY=<your key> node -e '
const { launchAgent } = require("./.github/scripts/launch-cursor-agent");
const { workerLaunchEnvVars } = require("./.github/scripts/execute-plan-launch");
const promptText = [
  "Probe only. Do not change any file, do not commit, do not open a pull request.",
  "Run this exact command once and reply with its output, nothing else:",
  "for v in OWNER_GH_TOKEN BOT_GH_TOKEN GH_TOKEN EXECUTE_PLAN_TOKEN; do if [ -n \"${!v}\" ]; then echo \"$v present\"; else echo \"$v absent\"; fi; done; echo \"injected: $CLOUD_AGENT_INJECTED_SECRET_NAMES\"",
].join("\n");
launchAgent({ apiKey: process.env.CURSOR_API_KEY, repoUrl: "https://github.com/KanopeeKa/AgathaCheck",
  promptText, envVars: workerLaunchEnvVars("probe-not-a-token") })
  .then((r) => console.log("agent:", r.id || JSON.stringify(r)));'
```

Read the agent's reply in the Cursor dashboard. "present" means non-empty.

| Reply | Meaning | Next |
|-------|---------|------|
| `OWNER_GH_TOKEN absent`, `BOT_GH_TOKEN absent`, `GH_TOKEN present`, `EXECUTE_PLAN_TOKEN present` | Blank overrides the dashboard secret | WP12; plans may run |
| `OWNER_GH_TOKEN present` | Cursor ignores the blank value | Keep the `tick` check (every worker stops with exit 3; the driver stops the phase on `launch-budget` after 5 launches). Do not start plans until Cursor supports removing a secret per launch; record the result in §Decision log of `execute-plan-v2.md` |

---

## WP12 — Authorizations need a trusted acknowledgement

**Branch:** `cursor/execute-plan-v2-wp12-<4 lowercase letters or digits>` · **PR title:**
`security: execute-plan authorizations are confirmed by the approve workflow (WP12)`

**Precondition:** no control issue is labelled `autonomous-approved` without `plan:complete`.
Authorizations posted before WP12 have no acknowledgement and would no longer count.

### Rules (contracts §3.3, new rule 6 and §3.3a)

- **Running worker** = the status comment has a `lease` **and** Cursor reports that run as
  `CREATING` or `RUNNING` (state-machine L1) **or** `UNKNOWN` (API error or no key — fail closed).
  For authorizations only the run status reported by Cursor is used; the `last_tick_at` time
  window of L2 stays a relaunch rule only. A lease whose run is `FINISHED`, `ERROR`, `CANCELLED`
  or `EXPIRED` is not running (a stale lease left in the status comment does not block).
- On every **created** `approve-autonomous` / `resume-autonomous` comment that passes
  `validateControlComment` (`scripts/lib/execute_plan_approval.js:45`), the approve handler decides:

  | Worker running? | Plan stopped? (`deriveControl(...).stopped`, without this comment) | Result |
  |---|---|---|
  | no | any | **Accept**: post the acknowledgement, then the driver pass as today |
  | yes | yes | **Ignore**: post the "not accepted, post again" note; no label, no new stop |
  | yes | no | **Stop**: add `needs-owner`, post the "plan stopped" note |

  "Stopped" uses the status comment's `stop` plus labels exactly as `deriveControl`
  (`scripts/lib/execute_plan_control.js:15-34`) does. After the owner removes `needs-owner` per
  runbook §7.5, a stop newer than the epoch still counts as stopped, so a resume posted while the
  last worker winds down is ignored with a note, never turned into a second stop.
- **Acknowledgement** (rule 6): a comment on the control issue authored by `github-actions[bot]`
  whose body is exactly
  `execute-plan: authorization accepted — comment <comment_id> — run <run_id>`
  where `<run_id>` is `GITHUB_RUN_ID` of the approve workflow run. It is valid only when
  `getWorkflowRun(run_id)` (`scripts/lib/execute_plan_github.js:315`) returns
  `path === '.github/workflows/execute-plan-approve.yml'`, `head_branch === 'main'` and
  `event === 'issue_comment'`. An approve or resume comment without a valid acknowledgement is
  invalid with reason `not-acknowledged`. Revoke comments and the `autonomous-revoked` label need no
  acknowledgement (they only restrict).
- **Notes** (posted by `github-actions[bot]`, once per comment because the event fires once):
  - Ignore: `execute-plan: <verb>-autonomous comment <id> not accepted — worker <agent_id> was still running at <ISO now>. Post it again once the worker has finished.`
  - Stop: `execute-plan: <verb>-autonomous comment <id> not accepted — posted while worker <agent_id> was running; plan stopped (needs-owner).`

### Code

1. New `scripts/lib/execute_plan_ack.js` (≤ 200 lines, pure + one client call):
   `ACK_RE`, `formatAck(commentId, runId)`, `formatIgnoredNote(…)`, `formatStoppedNote(…)`,
   `async acceptedAuthorizationIds(client, comments)` → `Set` of comment ids with a valid
   acknowledgement (verifies each referenced run once; ignores acks by any other author).
2. `scripts/lib/execute_plan_approval.js` — `findControlComments(comments, snapshot, config, { accepted })`:
   `accepted` is required (throw `TypeError` when missing). Approve/resume comments whose id is not
   in `accepted` are candidates with `valid: false, invalid_reason: 'not-acknowledged'`.
3. `scripts/lib/execute_plan_observe.js` — `loadPlanContext` computes
   `ctx.acceptedAuthorizations = await acceptedAuthorizationIds(client, ctx.comments)`; `observe`
   (`:162`) passes it. Worker and driver ticks therefore use the same acknowledged set.
4. `scripts/lib/execute_plan_approve.js` — in `handleControlComment` (`:128-143`) and
   `handleApprove` (`:36-104`), after validation and before `pass(...)`, apply the table above.
   Lease status: `clients.deps.getAgentRunStatus` (same seam as `execute_plan_driver_actions.js:285`);
   no lease → not running (first approval). Acknowledgement and notes are posted with
   `clients.read` (the `GITHUB_TOKEN` client); `needs-owner` is added with `clients.bot`.
   Dry-run posts nothing and returns the decision in `detail`.
5. `.github/scripts/execute-plan-approve.js` — pass `runId: env.GITHUB_RUN_ID` to
   `handleControlComment`. The workflow file needs no change (`issues: write` and `CURSOR_API_KEY`
   are already set, `.github/workflows/execute-plan-approve.yml:5-38`).

### Docs (same PR)

- `contracts.md` §3.3: rule 6 and a new §3.3a with the table, the acknowledgement format and the notes.
- `state-machine.md` control section: reason `not-acknowledged` for an invalid authorizing comment.
- `runbooks-proof-retirement.md` §7.5: after posting, wait for the acknowledgement comment; resume
  only a stopped plan; if a "not accepted" note appears, post the same line again once the worker
  has finished.
- `execute-plan-v2.md` decision log: "WP12 (planned)" → shipped wording with the PR number.

### Tests (offline)

- New `scripts/test/execute_plan_ack.test.js` (add to the governance block of
  `scripts/pre-push-changed.sh`, next to `:151`): valid ack; wrong author; malformed body; run with
  wrong `path`, `head_branch` or `event`; one run fetched once for several acks.
- `scripts/test/execute_plan_approval.test.js`: unacknowledged approve/resume → `not-acknowledged`;
  revoke unaffected; missing `accepted` throws.
- `scripts/test/execute_plan_approve.test.js`: the three table rows (no lease; `FINISHED` lease;
  `RUNNING` + stopped; `RUNNING` + running; `UNKNOWN` + running → stop); notes and ack bodies; dry-run
  posts nothing.
- Update existing `observe` / `tick` / `approve` tests that build approved plans so their fixtures
  include a valid acknowledgement; scenario files under `scripts/test/fixtures/execute-plan-v2/`
  change only if they hold raw comments.

### Acceptance

```bash
node --test scripts/execute_plan_runtime.test.js scripts/test/execute_plan_*.test.js scripts/test/launch_cursor_agent_bot_env.test.js
bash scripts/validate_docs.sh
./scripts/pre-push-changed.sh
```

---

## Kickoff prompt — Cursor, Composer 2.5 (WP11 or WP12)

Replace `<N>` with `11` or `12`.

```
You are a Cursor Cloud Agent implementing one security work package of execute-plan v2.
Work package: WP<N>.

Read these files in order and follow them exactly:
1. docs/agent-efficiency/plans/execute-plan-v2.md — section "2. Executor ground rules".
2. docs/agent-efficiency/plans/execute-plan-v2/work-packages-hardening.md — "Goal", "Order",
   then section "WP<N>" only.

This is a normal pull request into main. It is NOT an execute-plan run: do not use /execute-plan,
/babysit-plus or /babysit-uat, and ignore the execute-plan stop rules in AGENTS.md.

Steps:
a) Create the branch named in WP<N> from an up-to-date main.
b) Plan first: open a draft PR into main with the title from WP<N>. Its body is a checklist of
   every file, export, test and acceptance command listed in WP<N>, plus "## Docs" listing the
   docs WP<N> names.
c) Implement exactly the checklist. Anything not on it is out of scope; if the code does not
   match a cited path:line, follow the intent, and note the difference in the PR body.
d) Never print, log or echo a token value. Tests use made-up values.
e) Run every acceptance command; paste the output summary into the PR body.
f) Mark the PR ready when every box is ticked and CI is green. Never merge: the owner merges.
```

