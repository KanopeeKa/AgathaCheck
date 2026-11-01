---
name: execute-plan
description: Run a multi-phase autonomous v2 plan from a frozen snapshot in Claude Code (`/execute-plan [plan_id]`). Worker sessions use tick; end when actor is driver or stop.
---

# Execute-plan (Claude Code wrapper)

Read and follow `.cursor/skills/execute-plan/SKILL.md` (v2 loop). Contract: `AGENTS.md` §Execute-plan.

**Worker:** `node scripts/execute_plan_runtime.js tick <plan_id> --json --actor agent` → one `agent` action → `tick` again.

**Planning:** `init <plan_id>` on branch `cursor/<plan_id>-init`; end with the printed approval line.

**CI wait:** `watch-ci` / subscribe — never `sleep`.

**Plan PRs:** do not babysit or merge; owner controls (`execute-plan-hold`, `do-not-merge`,
approve / `resume-autonomous` / `revoke-autonomous`, `EXECUTE_PLAN_DRIVER=off`) — see cursor skill §Owner controls.

Spec: [`execute-plan-v2.md`](../../../docs/agent-efficiency/plans/execute-plan-v2.md).
