---
name: execute-plan
description: >-
  Multi-phase autonomous orchestrator (v2) — frozen snapshot, tick loop, driver, babysit+/uat.
  Contract: AGENTS.md §Execute-plan. Spec: docs/agent-efficiency/plans/execute-plan-v2.md.
disable-model-invocation: true
---

# Execute-plan (v2)

## Planning session

Write the plan files on branch `cursor/<plan_id>-init`, run
`node scripts/execute_plan_runtime.js init <plan_id>`, end the session with the printed approval line.

## Worker session

Run `node scripts/execute_plan_runtime.js tick <plan_id> --json --actor agent`, do the one `agent`
action returned, run `tick` again, end the turn with one line when the decision `actor` is
`driver` or `stop` is set.

`gate <plan_id>` is an alias of `tick` (no `--labels`).

## Driver loop

`tick` / `decide` ([state-machine §4.2](../../../docs/agent-efficiency/plans/execute-plan-v2/state-machine.md)):
control (D) → phases (P) → sync/release (S) → UAT (U). The Actions driver runs driver actions;
workers do not babysit or merge.

Spec: [`execute-plan-v2.md`](../../../docs/agent-efficiency/plans/execute-plan-v2.md).

**PR hygiene:** `/babysit-plus` (phase PRs) · `/babysit-uat` (release → `main`).

**Router:** `.cursor/agent-kernel/ROUTER.md` — profile `full` at phase select when implementing.

---

## Resolve `plan_id` (when omitted)

1. This conversation / control issue link  
2. Checked-out `cursor/*` or integration branch  
3. Control issue `plan:<id>` label  
4. `roadmap-next-child` on a legacy roadmap (schema 1 on disk only)  
5. Single open `busy` + `execute-plan` + `autonomous-approved`  

Ambiguous → `**Needs you:**` on control issue; do not guess.

---

## Roadmap chaining (legacy)

Parent `plan_kind: roadmap` with schema-1 snapshot on disk: `roadmap-status`, `roadmap-next-child`,
`roadmap-set-child` ([babysit-plus](../babysit-plus/SKILL.md) §Roadmap). New programmes use v2 `init`.

---

## Pre-UAT on final merge

`./scripts/babysit_uat_watch_preuat.sh <mergeCommit.oid> --timeout-min 90` (wraps `watch-preuat-sha`).

`complete-plan` (v2): `node scripts/execute_plan_runtime.js complete-plan <plan_id> --write`

---

## Related skills

| Skill | When |
|-------|------|
| `/babysit-plus` | Phase PRs |
| `/babysit-uat` | Release to `main` |
| `/e2e-debug` | Pre-UAT remedial |
| `/pre-push-verify` | Before push |
| `/spawn-sprint-agents` | Parallel phases when disjoint |
| `/canonical-docs` | Behaviour PRs |

Policy: [autonomous-pr-policy.md](../../../docs/agent-efficiency/autonomous-pr-policy.md) · Runtime: [execute-plan-runtime.md](../../../docs/agent-efficiency/execute-plan-runtime.md)
