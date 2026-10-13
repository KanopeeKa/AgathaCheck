---
name: execute-plan
description: >-
  Multi-phase autonomous orchestrator — frozen snapshot, phase loop, babysit+/uat.
  Contract: AGENTS.md §Operating rules › Execute-plan. Valid stops: §Stop rules below.
---

# Execute-plan

Orchestrates `.agents/plans/<plan_id>.{md,snapshot.json}` one phase at a time.

**Contract (gate exit `0`):** [`AGENTS.md`](../../AGENTS.md) §Operating rules › Execute-plan · [`execute-plan-instruction-stack.md`](../../docs/agent-efficiency/execute-plan-instruction-stack.md) · [`.agents/memory/execute-plan-autonomy.md`](../../../.agents/memory/execute-plan-autonomy.md)

## Stop rules (gate exit `0`)

When `node scripts/execute_plan_runtime.js gate <plan_id>` exits **`0`**, run-until-blocked. Escalation: [autonomous-pr-policy.md](../../docs/agent-efficiency/autonomous-pr-policy.md) §Escalation.

| Valid stops | Not stops (in-loop — continue) |
|-------------|--------------------------------|
| `complete-plan` → brief user chat OK | PR opened; CI green; babysit+ squash-merge |
| §Halt / §Escalation (revoke, `expired`, gate `2`, drift, CI/debt/merge failure, unclear goal, …) | Phase merged → next phase; worker returned |
| `session_limit` (~24h): `halt` + blocker alert; `resume-plan` | Control-issue telemetry; plan-only bootstrap commit |
| | e2e-debug → chain `/babysit-uat`; merge-lease FIFO wait |
| | Platform ended turn → resume via tools / next `/execute-plan` (no permission chat) |

User chat until `complete-plan`: blocker alerts only (see AGENTS.md). Milestones → control issue, PR body, `/opt/cursor/artifacts/`.

**Policy detail (do not restate here):** [autonomous-pr-policy.md](../../docs/agent-efficiency/autonomous-pr-policy.md) · [execute-plan-schema.md](../../docs/agent-efficiency/execute-plan-schema.md) · [execute-plan-runtime.md](../../docs/agent-efficiency/execute-plan-runtime.md) · [phase-exit-checklists.md](../../docs/agent-efficiency/phase-exit-checklists.md) · [plan-template.md](../../docs/agent-efficiency/plan-template.md)

**PR hygiene:** `/babysit-plus` (phase PRs) · `/babysit-uat` (final → `main`) — never plain `/babysit`. Pre-PR review + docs: [pr-review-cost-efficiency.md](../../docs/agent-efficiency/pr-review-cost-efficiency.md). **Merge:** squash when gates pass (`default_merge_mode: auto`).

**Router:** `.cursor/agent-kernel/ROUTER.md` — if execute-plan is active (gate `0`), re-read **AGENTS.md §Execute-plan** at classification. Profile `full` at phase select + strengthen; **skip strengthen** on resume-only (babysit, CI watch, `next_action` set).

---

## Invocation

| Command | When |
|---------|------|
| `/execute-plan` | Resume programme — same as continue; not permission to start next phase ([AGENTS.md](../../AGENTS.md)) |
| `/execute-plan <plan_id>` | Named plan |
| `/execute-plan resume` | After revoke removed + `resume-plan` on control issue |

## Resolve `plan_id` (when omitted)

1. This conversation / control issue link  
2. Checked-out `cursor/*` or integration branch (snapshot on branch)  
3. Control issue `plan:<id>` label  
4. Roadmap parent → `roadmap-next-child`  
5. Single open `busy` + `execute-plan` + `autonomous-approved`  

Ambiguous → `**Needs you:**` on control issue; do not guess.

---

## Before `approve-autonomous` (plan authoring)

Follow [plan-template.md](../../docs/agent-efficiency/plan-template.md): snapshot validate, `init-control-issue`, integration `base_branch` for 2+ phases, sanity check, then `approve-autonomous <plan_id>` on control issue. `approved_until` = 48h from approval.

---

## Session preflight (every run)

1. `git fetch origin main` (+ `origin/<base_branch>`)  
2. Resolve `plan_id` if needed  
3. Checkout branch carrying snapshot (`artifact_branch_policy: phase-branch`)  
4. **Gate:** `node scripts/execute_plan_runtime.js gate <plan_id> --labels execute-plan,plan:<plan_id>,autonomous-approved`  
   - Exit `2` → halt; no work  
   - Exit `0` → re-read **AGENTS.md §Execute-plan**; obey gate stdout **next action** (first tool step — preflight is not a deliverable)  
5. **Resume** (if applicable): `resume-check` — mismatch → halt unless `accept-head` on issue  
6. `current-phase`; rebase phase branch on `origin/<base_branch>`  
7. Control issue `start-work` + `busy` on first session (no Project board writes)  
8. **Session limit** (~24h): safe step → `halt --reason session_limit` + `resume-plan` in chat (blocker only)

Turn boundaries: [execute-plan-instruction-stack.md](../../docs/agent-efficiency/execute-plan-instruction-stack.md) §Cloud turn mechanics. CI wait: subscribe + tool-only until green or §Halt (≤5 lines in babysit+ / stack doc).

---

## Multi-phase integration

2+ phases: `cursor/<plan_id>-integration-<suffix>` = `base_branch`; phase PRs target integration; one release PR integration → `main` + `/babysit-uat`. Single phase: `base_branch: main`. Details: execute-plan-schema §Multi-phase integration.

---

## Roadmap chaining

Standing grant beyond one `plan_id`: on child `complete-plan`, bootstrap next child in **same session** (reuse grant; still gate + control issue). Parallel waves → `/spawn-sprint-agents` when disjoint paths. Parent `plan_kind: roadmap`: `roadmap-status`, `roadmap-next-child`, `roadmap-set-child`. Soft closers: AGENTS.md §Execute-plan.

---

## Phase delegation

| Role | Owns |
|------|------|
| **Orchestrator** | Gate, runtime, control issue, PR, babysit+/uat, merge, next phase |
| **Phase worker** | Implement on phase branch ([phase-implementer.md](../agent-kernel/workers/phase-implementer.md)); summary **to orchestrator only** — never user chat |

Default: worker or inline through PR + babysit+ without chat stop. `spawn_allowed: true` → `/spawn-sprint-agents` first.

| PR base | After CI-ready |
|---------|----------------|
| Not `main` | `/babysit-plus` |
| `main` (final) | `/babysit-uat`; pre-UAT red → `/e2e-debug` then **chain** `/babysit-uat` same session |

Snag ladder: [atomic-pr-policy.md](../../docs/agent-efficiency/atomic-pr-policy.md). Drift → `halt --reason drift`.

---

## Issue hygiene

| When | Control issue | User chat |
|------|---------------|-----------|
| Session start | `start-work` + `busy` | — |
| Milestones | Short comment | **No** routine status |
| Halt / needs human | `halt` / `**Needs you:**` | One short blocker paragraph + link |
| Done | `complete-plan` | Brief complete only after CLI |

---

## Phase loop

Until all phases `merged` or halt:

1. **Select** — first `pending` or `next_action`; checkout `phase.branch`; Router strengthen unless resume-only  
2. **Mark** — `set-phase … in_progress` + `sync-runtime`; commit plan artifacts on phase branch  
3. **Implement** — `allowed_paths` only; `./scripts/pre-push-changed.sh`; delegate per §Phase delegation  
4. **PR** — target `base_branch`; `set-phase` with `--pr-url` / `--pr-head`  
5. **Babysit** — skill per table above through **merge-done** (`MERGED`, `merge_commit` on base)  
6. **Complete** — `set-phase … merged`; control-issue comment  
7. **Next** — loop §1 immediately if more `pending`; else integration → `main` PR + `/babysit-uat` + `complete-plan`

`complete-plan` docs gate: fold/delete `changes/` per plan; `docs_targets` on control issue. CLI: `node scripts/execute_plan_runtime.js complete-plan <plan_id> --write`

Pre-UAT on final merge: `./scripts/babysit_uat_watch_preuat.sh <mergeCommit.oid> --timeout-min 90` — do not poll deploy-uat.

---

## Halt / resume / escalation

Halt: revoke, `expired`, escalation, drift, CI exhausted, debt create failure, merge failure, `session_limit`. CLI: [execute-plan-runtime.md](../../docs/agent-efficiency/execute-plan-runtime.md). **`expired`:** re-approve + `resume-plan` only — never ask which phase next.

Resume: remove revoke → `resume-plan` → `/execute-plan <plan_id> resume` → `resume-check` → continue `next_action`.

Escalation list: autonomous-pr-policy §Escalation (always halt).

---

## Related skills

| Skill | When |
|-------|------|
| `/babysit-plus` | Phase PRs |
| `/babysit-uat` | Release to `main` |
| `/e2e-debug` | Pre-UAT remedial |
| `/pre-push-verify` | Before push |
| `/spawn-sprint-agents` | `spawn_allowed` |
| `/canonical-docs` | Behaviour PRs |
| Task `generalPurpose` | Phase worker |
