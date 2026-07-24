---
name: execute-plan
description: Run a multi-phase autonomous plan from a frozen snapshot; delegates PR hygiene to /babysit-plus (default merge mode auto).
---

# Execute-plan

Orchestrate an approved multi-phase plan. Read and follow **`.cursor/skills/execute-plan/SKILL.md`** — do not improvise policy.

## Quick start

```bash
# Preflight (every session) — exit 0 = proceed without asking human
node scripts/execute_plan_runtime.js gate <plan_id> --labels execute-plan,plan:<plan_id>,autonomous-approved
node scripts/execute_plan_runtime.js current-phase <plan_id>
```

## Rules

1. **Autonomy contract** — gate exit `0` → proceed; never ask "shall I continue?" in user chat (control issue for blockers only)
2. **Babysit-plus always** — never plain `/babysit` during execute-plan
3. **Default merge mode `auto`** unless snapshot sets `default_merge_mode` or per-phase `merge_mode`
4. **Phase gate = merge-done** — PR merged into base before next phase
5. **Integration branch** — 2+ phases: `base_branch` = integration; one final PR to `main`
6. **Per-phase worker** — Task sub-agent for implementation; orchestrator owns babysit+ / merge
7. **Halt only on revoke / escalation / session_limit (~24h)** — do not close PRs; see autonomous-pr-policy §Halt and resume
8. **48h `approved_until`** — mandatory autonomy window; re-approve if expired
9. **Issue hygiene** — control issue: comment milestones; `start-work` + `busy` on session start; close on complete (`complete-plan --write`). After merge: `uat_queue_runtime.js enqueue --write` — **never** Task sub-agents to poll UAT

## Resume

After human removes `autonomous-revoked` and comments `resume-plan <plan_id>` (also after `session_limit` checkpoint):

```
/execute-plan <plan_id> resume
```

Policy: `docs/agent-efficiency/autonomous-pr-policy.md` · Memory: `.agents/memory/execute-plan-autonomy.md`
