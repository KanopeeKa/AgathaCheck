---
name: execute-plan
description: >-
  Multi-phase autonomous orchestrator (v2) — frozen snapshot, tick loop, Actions driver.
  Contract: AGENTS.md §Execute-plan. Spec: docs/agent-efficiency/plans/execute-plan-v2.md.
disable-model-invocation: true
---

# Execute-plan (v2)

## Planning session

Write the plan file on branch `cursor/<plan_id>-init`. Delivery plans, README index rows, and other
docs belong on `main` first (normal docs PR) — **never** on `-init`; see
[`plan-template.md`](../../../docs/agent-efficiency/plan-template.md) § Authoring workflow.

Run `node scripts/execute_plan_runtime.js init <plan_id>`, end the session with the printed approval line.

## Worker session

Run `env -u OWNER_GH_TOKEN -u BOT_GH_TOKEN node scripts/execute_plan_runtime.js tick <plan_id> --json --actor agent`, do the one `agent`
action returned, run `tick` again, end the turn with one line when the decision `actor` is
`driver` or `stop` is set.

Each command may run in a fresh shell, so prefix every `tick` with `env -u`; `unset` does not carry over.

**`triage-review` action** (unresolved review threads; `tick` returns it before any merge): run
`node scripts/babysit_pr_reviews.js wait --pr <n>` and handle every thread it lists, not only the ones in
the evidence. Apply [autonomous-pr-policy](../../../docs/agent-efficiency/autonomous-pr-policy.md) §Review triage —
fix must-fix and safe nits on the branch (`./scripts/pre-push-changed.sh` before the push), debt issue per
§Debt issues for ignored or skipped items — then reply on each thread (`Fixed in <sha>` / `False positive: …` /
`Deferred to #<n>`) and resolve it. `tick` relaunches the action while any thread stays unresolved.

`gate <plan_id>` is an alias of `tick` (no `--labels`).

## Driver loop

`tick` / `decide` ([state-machine §4.2](../../../docs/agent-efficiency/plans/execute-plan-v2/state-machine.md)):
control (D) → phases (P) → sync/release (S) → UAT (U). The Actions driver runs driver actions
(phase branches, sync/release PRs, worker launch, arm auto-merge, pre-UAT watch); workers implement
and fix CI only — they do not babysit or merge.

Spec: [`execute-plan-v2.md`](../../../docs/agent-efficiency/plans/execute-plan-v2.md).

**Plan PRs:** the driver arms and merges; workers push fixes on plan branches. Humans and agents
**must not** run `/babysit-plus`, `/babysit-uat`, or `/babysit` on execute-plan phase, sync, release,
or remedial PRs, and must not merge or push to plan branches outside a worker `tick` action.
Use those skills only for ordinary (non-plan) PRs.

**Router:** `.cursor/agent-kernel/ROUTER.md` — profile `full` at phase select when implementing.

---

## Resolve `plan_id` (when omitted)

1. This conversation / control issue link  
2. Checked-out `cursor/*` or integration branch  
3. Control issue `plan:<id>` label  
4. `roadmap-next-child` on a legacy roadmap (schema 1 on disk only)  

Ambiguous → `**Needs you:**` on control issue; do not guess.

---

## Owner controls

| Control | Effect |
|---------|--------|
| **`execute-plan-hold`** (PR label) | Pause auto-merge and worker launch for that PR; budgets unchanged. Remove when ready. |
| **`do-not-merge`** (PR label) | STOP — driver treats PR as blocked (`pr-blocked`). |
| **`approve-autonomous`** comment | Exact line printed by `init`; starts the programme. |
| **`resume-autonomous`** comment | After STOP/revoke: valid resume clears **`needs-owner`** and **`autonomous-revoked`** via the approve workflow; same `sha256:` hash, new `until` (≤ 14 days); renews time and budgets. |
| **`revoke-autonomous`** comment or **`autonomous-revoked`** label | Disables auto-merge; scope check red on open plan PRs. |
| **`EXECUTE_PLAN_DRIVER`** repo variable | `off` = kill switch (approve + driver workflows stop immediately). |

Day-to-day detail: [runbooks §7.5](../../../docs/agent-efficiency/plans/execute-plan-v2/runbooks-proof-retirement.md).

---

## Roadmap chaining (legacy)

Parent `plan_kind: roadmap` with schema-1 snapshot on disk: `roadmap-status`, `roadmap-next-child`,
`roadmap-set-child` ([babysit-plus](../babysit-plus/SKILL.md) §Roadmap). New programmes use v2 `init`.

---

## Pre-UAT and programme completion

The driver runs pre-UAT watch and UAT promotion automatically after the release merge (`tick` U-stage;
`verifyComplete` in the spec). Do not run `./scripts/babysit_uat_watch_preuat.sh` or poll deploy-uat for
plan PRs unless debugging outside the driver.

`node scripts/execute_plan_runtime.js complete-plan <plan_id> --write` is a **recovery tool** when the
control issue must be closed manually (for example after a STOP or drift). Normal completion is observed
on GitHub by the driver — not by an agent calling `complete-plan`.

---

## Related skills

| Skill | When |
|-------|------|
| `/babysit-plus` | Non-plan PRs only |
| `/babysit-uat` | Non-plan release to `main` only |
| `/e2e-debug` | Pre-UAT remedial (non-plan or manual recovery) |
| `/pre-push-verify` | Before push on worker branches |
| `/spawn-sprint-agents` | Parallel work outside execute-plan |
| `/canonical-docs` | Behaviour changes in worker scope |

Policy: [autonomous-pr-policy.md](../../../docs/agent-efficiency/autonomous-pr-policy.md) · Runtime: [execute-plan-runtime.md](../../../docs/agent-efficiency/execute-plan-runtime.md)
