---
name: execute-plan
description: Run a multi-phase autonomous plan from a frozen snapshot in Claude Code (`/execute-plan [plan_id] [resume]`). Gate exit 0 means run until blocked — never stop, summarise or ask between PRs.
---

# Execute-plan (Claude Code wrapper)

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
