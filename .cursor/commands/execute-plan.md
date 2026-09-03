---
name: execute-plan
description: Run a multi-phase autonomous plan from a frozen snapshot; babysit+ on phase PRs, babysit-uat on final merge to main.
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

1. **Autonomy contract** — gate exit `0` → proceed; never ask "shall I continue?" in user chat for routine work. **Blockers:** control issue (detail) + short chat alert (issue link).
2. **Babysit-plus** on intermediate phase PRs; **babysit-uat** on final PR to `main` — never plain `/babysit`
3. **Always merge** when gates pass (no manual/labeled modes)
4. **Phase gate = merge-done** — PR merged into base before next phase (final main PR also needs pre-UAT green)
5. **Integration branch** — 2+ phases: `base_branch` = integration; one final PR to `main`
6. **Per-phase worker** — Task sub-agent for implementation; orchestrator owns babysit+ / merge
7. **Halt only on revoke / escalation / session_limit (~24h)** — do not close PRs; see autonomous-pr-policy §Halt and resume
8. **48h `approved_until`** — mandatory autonomy window; re-approve if expired
9. **Issue hygiene** — control issue: comment milestones; `start-work` + `busy` on session start; close on complete (`complete-plan --write`). Final main merge: `/babysit-uat` watches pre-UAT for merge SHA — **never** poll deploy
10. **Turn boundaries ≠ stop** — each cloud turn ends when you respond; commit/push/PR update, post control-issue milestone, state `next_action`, then **continue the phase loop** in-session or on resume. Never ask "shall I continue?" in user chat. Gate exit `2` → `halt` on control issue only.

## Resume

After human removes `autonomous-revoked` and comments `resume-plan <plan_id>` (also after `session_limit` checkpoint):

```
/execute-plan <plan_id> resume
```

Policy: `docs/agent-efficiency/autonomous-pr-policy.md` · Memory: `.agents/memory/execute-plan-autonomy.md`
