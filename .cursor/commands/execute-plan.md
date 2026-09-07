---
name: execute-plan
description: Run a multi-phase autonomous plan from a frozen snapshot; babysit+ on phase PRs, babysit-uat on final merge to main.
---

# Execute-plan

Orchestrate an approved multi-phase plan. Read and follow **`.cursor/skills/execute-plan/SKILL.md`** — do not improvise policy.

**Router:** `.cursor/agent-kernel/ROUTER.md` at phase start — see skill §Router.

## Quick start

```bash
# Resolve plan_id from conversation / branch / control issue when omitted (skill §Resolve plan_id)
# Checkout phase or integration branch so snapshot exists locally, then:
node scripts/execute_plan_runtime.js gate <plan_id> --labels execute-plan,plan:<plan_id>,autonomous-approved
node scripts/execute_plan_runtime.js current-phase <plan_id>
```

Bare **`/execute-plan`** (no id) is valid when context is unambiguous — see skill §Resolve plan_id.

## Rules

1. **Run-until-blocked** — gate exit `0` → stay in the phase loop until merge-done, `complete-plan`, or §Halt; never ask "shall I continue?" mid-flow
2. **Babysit-plus** on intermediate phase PRs; **babysit-uat** on final PR to `main` — never plain `/babysit`
3. **Always merge** when gates pass (no manual/labeled modes)
4. **Phase gate = merge-done** — PR merged into base before next phase (final main PR also needs pre-UAT green)
5. **Integration branch** — 2+ phases: `base_branch` = integration; one final PR to `main`
6. **Per-phase worker** — Task sub-agent for implementation; orchestrator owns babysit+ / merge
7. **Halt only on revoke / escalation / session_limit (~24h)** — the only routine checkpoint; see autonomous-pr-policy §Halt and resume
8. **48h `approved_until`** — mandatory autonomy window; re-approve if expired
9. **Issue hygiene** — control-issue milestones are telemetry, not stop signals; `complete-plan --write` closes the plan; `/babysit-uat` on final main merge — **never** poll deploy
10. **e2e-debug → babysit-uat** — mandatory chain on pre-UAT failure; never stop with an open remedial PR
11. **Artifact branch** — checkout phase/integration branch before gate; snapshot may not exist on `main`

## Resume

After human removes `autonomous-revoked` and comments `resume-plan <plan_id>` (also after `session_limit` checkpoint):

```
/execute-plan resume
/execute-plan <plan_id> resume
```

Policy: `docs/agent-efficiency/autonomous-pr-policy.md` · Memory: `.agents/memory/execute-plan-autonomy.md`
