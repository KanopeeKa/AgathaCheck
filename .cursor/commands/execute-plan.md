---
name: execute-plan
description: Run a multi-phase autonomous plan from a frozen snapshot; delegates PR hygiene to /babysit-plus (default merge mode auto).
---

# Execute-plan

Orchestrate an approved multi-phase plan. Read and follow **`.cursor/skills/execute-plan/SKILL.md`** — do not improvise policy.

## Quick start

```bash
# Preflight (every session)
node scripts/execute_plan_runtime.js gate <plan_id> --labels execute-plan,plan:<plan_id>,autonomous-approved
node scripts/execute_plan_runtime.js current-phase <plan_id>
```

## Rules

1. **Babysit-plus always** — never plain `/babysit` during execute-plan
2. **Default merge mode `auto`** unless snapshot sets `default_merge_mode` or per-phase `merge_mode`
3. **Phase gate = merge-done** — PR merged into base before next phase
4. **Halt only on revoke** — do not close PRs; see autonomous-pr-policy §Halt and resume
5. **48h `approved_until`** — mandatory; re-approve if expired
6. **Issue hygiene** — control issue: comment milestones; `start-work` + `busy` on session start; close on complete (`complete-plan --write`). Project board columns are human/Actions — agents do not update them. After merge: `uat_queue_runtime.js enqueue` (babysit-plus §8) — **never** spawn Task sub-agents to poll UAT.

## Resume

After human removes `autonomous-revoked` and comments `resume-plan <plan_id>`:

```
/execute-plan <plan_id> resume
```

Policy: `docs/agent-efficiency/autonomous-pr-policy.md`
