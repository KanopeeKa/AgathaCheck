---
name: execute-plan
description: Run a multi-phase autonomous plan from a frozen snapshot in Claude Code (`/execute-plan [plan_id] [resume]`). Gate exit 0 means run until blocked — never stop, summarise or ask between PRs.
---

# Execute-plan (Claude Code wrapper)

## v2 plans (snapshot schema_version 2)

**Planning session:** Write the plan files on branch `cursor/<plan_id>-init`, run
`node scripts/execute_plan_runtime.js init <plan_id>` with the Bash tool, end the session with the printed
approval line.

**Worker session:** Run `node scripts/execute_plan_runtime.js tick <plan_id> --json --actor agent` with the Bash
tool, do the one `agent` action returned (GitHub MCP tools for reads), run `tick` again, end the turn with one line
(`worker done: <state>`) when the decision `actor` is `driver` or `stop` is set. After a `fix-ci` push, wait with
`node scripts/execute_plan_runtime.js watch-ci` (background), never `sleep`.

**Driver loop:** `tick` / `decide` ([state-machine §4.2](../../../docs/agent-efficiency/plans/execute-plan-v2/state-machine.md)):
control (D) → phases (P) → sync/release (S) → UAT (U). The Actions driver runs driver actions (phase branches,
sync/release PRs, worker launch, arm auto-merge); workers do not babysit or merge. Handoff and action table:
[contracts §3.6–3.7](../../../docs/agent-efficiency/plans/execute-plan-v2/contracts.md).

There is no stop table for v2: `tick` decides. Spec:
[`execute-plan-v2.md`](../../../docs/agent-efficiency/plans/execute-plan-v2.md).

## v1 plans (schema 1)

Read and follow `.cursor/skills/execute-plan/SKILL.md` (procedure and §Stop rules). Contract for all agents:
`AGENTS.md` §Operating rules › Execute-plan. Claude Code mechanics:
`docs/agent-efficiency/execute-plan-instruction-stack.md` §Claude Code.

This file is a pointer only. Do not copy the procedure here.

## Claude Code adaptations

- **Gate:** `node scripts/execute_plan_runtime.js gate <plan_id> --labels …` with the control-issue labels read via
  the GitHub MCP tools. Exit `0` authorises PRs, pushes to the snapshot's phase/integration branches, PR-activity
  subscription and squash-merge when merge gates pass — without asking.
- **Phase workers:** `Agent` tool with `.cursor/agent-kernel/workers/phase-implementer.md` as the brief. The worker's
  summary is input for you, never for user chat.
- **Waiting / parking / resume after compaction:** instruction stack §Claude Code.
