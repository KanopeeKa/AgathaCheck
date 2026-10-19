---
title: Execute-plan v2 — work split and kickoff prompts
owner: Kanopee
audience: both
status: active
last_updated: 2026-10-15
tags: [agent, execute-plan, autonomy, cursor, claude-code]
---
# Execute-plan v2 — work split and kickoff prompts

Part of [execute-plan-v2.md](../execute-plan-v2.md). For the owner: who should build each work
package, what can run in parallel, and the exact prompt to paste. Prompts are self-contained;
agents never need this conversation.

## Who builds what

| WP | Recommended executor | Why | Can run in parallel with |
|----|---------------------|-----|--------------------------|
| WP1 GitHub client | Claude Code | Pure Node; retries, pagination, error mapping | WP2, WP7c |
| WP2 Scope matcher | Claude Code | Security-critical, many precedence cases | WP1, WP7c |
| WP3 Approval, snapshot, `init` | Claude Code | Hashing and strict validation | WP7c |
| WP4a Pure decision logic | Claude Code | Hardest logic; 32 scenarios | — |
| WP4b Observe, `tick`, status | Cursor or Claude Code | Plumbing onto fully specified shapes | — |
| WP5 UAT stage | Claude Code | Subtle ancestry and failure rules | — |
| WP6a Cursor skills/commands | **Cursor** | Cursor skill/command conventions | WP6b, WP7a |
| WP6b Claude skill, AGENTS, memory, link check | Claude Code | Claude Code mechanics, Stop hook | WP6a, WP7a |
| WP7a Scope check + CI wiring | Claude Code | `pull_request_target` hardening | WP6a, WP6b |
| WP7b Approve + driver | Claude Code | Control-flow and token rules | — |
| WP7c Cursor launch adapter | **Cursor** | Needs Cursor API docs and dashboard checks | WP1–WP6 |
| WP8 Rulesets + live verification | **Cursor** + owner | Acts as the bot through the temporary secret `BOT_GH_TOKEN` | — |
| WP9 Proof run (init step) | **Cursor** + owner | Exercises the real worker path | — |
| WP10 Retirement | Claude Code | Deletions across code and docs | — |

Owner steps in order: Phase 0 decisions ✔ → identity and repo secret ✔ (bot `pawpet-bot`) → merge
each WP PR → after WP7b: `EXECUTE_PLAN_DRIVER=dry-run` → before WP8: add Cursor secret `BOT_GH_TOKEN` = bot
token → WP8 rulesets (§7.2) and auto-merge (§7.3) →
approval comment of the proof run → go / no-go after WP9.

## Plan-first rule (all executors)

Before writing code, the executor opens a **draft PR** whose body is a checklist of every file,
export, test and acceptance command of the WP, plus a `## Docs` section. Code follows the
checklist; anything not on it is out of scope. This keeps a fast model on rails and gives the
owner a one-glance review.

## Kickoff prompt — Cursor (model per the Cloud Agent model policy), any WP

Replace `<N>`, `<title>` and `<sections>` from the table at the end of this file.

```
You are a Cursor Cloud Agent implementing one work package of the execute-plan v2 build.
Work package: WP<N> — <title>.

Read these files in order and follow them exactly:
1. docs/agent-efficiency/plans/execute-plan-v2.md — section "2. Executor ground rules".
2. <sections>

This is a normal pull request into main. It is NOT an execute-plan run: do not use /execute-plan,
/babysit-plus or /babysit-uat, and ignore the execute-plan stop rules in AGENTS.md.

Steps:
a) Create branch cursor/execute-plan-v2-wp<N>-<4 random lowercase letters or digits> from main.
b) Plan first: open a draft PR into main titled "execute-plan v2: WP<N> <title>". Its body is a
   checklist of every file, export, test and acceptance command listed for WP<N>, plus "## Docs".
c) Run every VERIFY in WP<N> and follow its decision. If no listed outcome matches, stop and
   comment on the PR with the command and its output.
d) Change only the files WP<N> lists; respect its "Do not touch" list.
e) Run the WP<N> acceptance commands exactly as written; all must pass.
f) Tick the checklist and mark the PR ready for review. Do not merge.
```

## Kickoff prompt — Claude Code, any WP

```
Implement WP<N> (<title>) of docs/agent-efficiency/plans/execute-plan-v2.md.
Read section "2. Executor ground rules" of that file, then <sections>.
This is a normal PR into main, not an execute-plan run. Use this session's branch.
Plan first: open a draft PR whose body is the WP<N> checklist (files, exports, tests, acceptance
commands, ## Docs). Follow each VERIFY decision; change only the listed files; run the acceptance
commands; mark the PR ready; do not merge.
```

## Cursor-specific prompts (tasks Cursor is better placed to do)

### WP7c — Cursor launch adapter

```
You are a Cursor Cloud Agent. Implement WP7c of the execute-plan v2 build: the Cursor launch
adapter. Read docs/agent-efficiency/plans/execute-plan-v2.md (section 2) and
docs/agent-efficiency/plans/execute-plan-v2/work-packages-platform.md (section WP7c).

Context you know better than other agents: the Cursor Cloud Agents API and dashboard.
1. Read .github/scripts/launch-cursor-agent.js and .github/scripts/monitor-cursor-agent.js; reuse
   their request shape, endpoints and status names exactly.
2. Answer the two VERIFY questions of WP7c from the official Cursor API documentation and the
   Cursor dashboard:
   - Does workOnCurrentBranch: true with startingRef = an existing branch make the agent commit
     and push to that branch? Quote the doc sentence in the PR body.
   - Does a Cloud Agent launched through the API receive the repo's cloud secrets?
   Follow the decision written in WP7c for each answer.
3. Create .github/scripts/execute-plan-launch.js (launchPlanAgent, getAgentRunStatus) and
   scripts/test/execute_plan_launch.test.js using an injected fetch (no network in tests).
4. Branch cursor/execute-plan-v2-wp7c-<4 chars>; plan-first draft PR into main; run
   node --test scripts/test/execute_plan_launch.test.js; mark ready; do not merge.
This is not an execute-plan run: do not use /execute-plan or /babysit-plus.
```

### WP6a — Cursor skills and commands

```
You are a Cursor Cloud Agent. Implement WP6a of the execute-plan v2 build: update the Cursor
execute-plan skill, the /execute-plan command and the babysit skills for v2. Read
docs/agent-efficiency/plans/execute-plan-v2.md (section 2),
docs/agent-efficiency/plans/execute-plan-v2/work-packages-platform.md (section WP6a) and
docs/agent-efficiency/plans/execute-plan-v2/state-machine.md (section 4.2, to describe the loop
correctly). Keep Cursor's skill and command conventions (frontmatter, headings) as they are in the
existing files. Do exactly items 1–6 of WP6a; v1 text stays except where an item changes it.
Run the WP6a acceptance commands. Branch cursor/execute-plan-v2-wp6a-<4 chars>; plan-first
draft PR into main; mark ready; do not merge. This is not an execute-plan run.
```

### WP8 — Rulesets and live verification (with the owner)

```
You are a Cursor Cloud Agent. Every bot action uses the secret BOT_GH_TOKEN (never your own GH_TOKEN). Run WP8 of the
execute-plan v2 build: docs/agent-efficiency/plans/execute-plan-v2/work-packages-platform.md
(section WP8) and docs/agent-efficiency/plans/execute-plan-v2/runbooks-proof-retirement.md
(sections 7.2–7.4). Verification only: do not change code.
Do steps 1, 2 and 4 yourself; steps 3 and 5 are the owner's — stop before each, post what you
observed as a comment on the sandbox control issue (or the probe PR), and wait for the owner.
For every step, compare the observation with the expected result written in WP8; if it differs,
stop and report the links. Never merge anything; close the probe PR when step 2 is done.
```

### WP9 — Proof run, init step

```
You are a Cursor Cloud Agent. Start the execute-plan v2 proof run: read
docs/agent-efficiency/plans/execute-plan-v2/runbooks-proof-retirement.md section 8.
1. Create branch cursor/proof-build-label-7f3a-init from main.
2. Add .agents/plans/proof-build-label-7f3a.md with exactly the plan file content of section 8
   (replace <date> with today's date, YYYY-MM-DD).
3. Run: node scripts/execute_plan_runtime.js init proof-build-label-7f3a --window-days 3
4. Reply with the approval line it prints, and end your session. Do nothing else.
```

## Per-WP `<sections>` for the generic prompts

| WP | `<title>` | `<sections>` |
|----|-----------|--------------|
| 1 | GitHub client | `execute-plan-v2/work-packages-runtime.md` (top rules + WP1) |
| 2 | Scope matcher | `execute-plan-v2/contracts.md` §3.1; `execute-plan-v2/work-packages-runtime.md` (top rules + WP2) |
| 3 | Approval, snapshot v2, init | `execute-plan-v2/contracts.md` §3.1–3.4, §3.8; `execute-plan-v2/work-packages-runtime.md` (top rules + WP3) |
| 4a | Pure decision logic | `execute-plan-v2/contracts.md` §3.5–3.8; `execute-plan-v2/state-machine.md` (all); `execute-plan-v2/work-packages-tick.md` (WP4a) |
| 4b | Observe, tick, status | `execute-plan-v2/contracts.md` §3.5–3.8; `execute-plan-v2/state-machine.md` §4.0–4.1; `execute-plan-v2/work-packages-tick.md` (WP4b) |
| 5 | UAT stage | `execute-plan-v2/state-machine.md` §4.0, §4.2 (U-rules), §4.4–4.5; `execute-plan-v2/work-packages-tick.md` (WP5) |
| 6b | Claude skill, AGENTS, memory, link check | `execute-plan-v2/work-packages-platform.md` (WP6b) |
| 7a | Scope check and CI wiring | `execute-plan-v2/work-packages-platform.md` (rules, token table, WP7a) |
| 7b | Approve and driver workflows | `execute-plan-v2/contracts.md` §3.3, §3.5–3.7; `execute-plan-v2/work-packages-platform.md` (token table, WP7b) |
| 10 | Retirement | `execute-plan-v2/runbooks-proof-retirement.md` §9 |
