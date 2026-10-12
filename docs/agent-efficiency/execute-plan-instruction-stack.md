---
title: Execute-plan instruction stack (Cloud Agents)
owner: Documentation Team
audience: agent
status: active
last_updated: 2026-10-12
tags: [agent-efficiency, execute-plan, cloud-agents]
---

# Execute-plan instruction stack (Cloud Agents)

**Purpose:** When `/execute-plan` gate exits `0`, several **always-on** platform and repo instructions still appear in context. This document states **which instruction wins** so orchestrators do not treat a phase merge, babysit+ completion, or turn boundary as programme completion.

**Canonical loop:** [autonomous-pr-policy.md](./autonomous-pr-policy.md) §Execute-plan overrides · Skill: `.cursor/skills/execute-plan/SKILL.md` · Memory: `.agents/memory/execute-plan-autonomy.md`

---

## When this applies

| Condition | Instruction stack rules apply |
|-----------|-------------------------------|
| `node scripts/execute_plan_runtime.js gate <plan_id>` exits **`0`** | **Yes** — run-until-blocked is authoritative |
| Gate exit **`2`**, revoked, or no standing grant | **No** — use generic agent + human checkpoint rules |
| Plain PR / no execute-plan | **No** — babysit+ and PR hygiene only |

Plan-specific binding text (e.g. `agatha-care-journey` §Orchestrator contract) **adds** programme constraints; it does not relax this stack.

---

## Instruction precedence (gate exit `0`)

Read **top wins** when two instructions conflict:

| Priority | Source | Orchestrator behavior |
|----------|--------|----------------------|
| 1 | Frozen snapshot + plan markdown (`next_action`, phases, `base_branch`) | Follow phase loop until `complete-plan` or §Halt |
| 2 | `/execute-plan` skill §Autonomy contract, §Run-until-blocked, §Orchestrator visibility | No routine user chat; merge-done → next phase **same session** |
| 3 | `autonomous-pr-policy.md` §Execute-plan overrides | Narrow generic “stop and ask” / chat evidence rules |
| 4 | `AGENTS.md` §Execute-plan orchestration | Same as row 2–3 (Cloud-specific summary) |
| 5 | `.agents/memory/execute-plan-autonomy.md` | Phase boundary table; conflict resolution |
| 6 | `/babysit-plus` skill | Triage, CI, **squash-merge** — then **return to execute-plan loop** (not session end) |
| 7 | Generic testing / diligence (platform) | Evidence → PR body, control issue, `/opt/cursor/artifacts/` — **not** milestone chat |
| 8 | Generic git / Cloud task (“update PR each turn”, summary) | Update PR in-loop; **do not** treat summary as a valid stop |
| 9 | User communication style (polish, proportional reply) | **Defer** until `complete-plan` or blocker alert |

**Rule of thumb:** If the action sounds like “report progress to the user,” it is **wrong** during active execute-plan unless it is a §Halt / `**Needs you:**` alert.

---

## Common false stop signals

These feel like “done” but are **in-loop** steps (skill §Run-until-blocked):

| False stop | Required next step (same session when possible) |
|----------|-----------------------------------------------|
| Phase PR opened | Babysit+, CI watch, merge when green |
| CI green | Merge (babysit+ §7), `set-phase merged`, control-issue telemetry |
| Babysit+ merge to integration | **Immediately** checkout next `pending` phase and implement (or spawn phase worker) |
| `chore(plan): phase N in progress` only | Insufficient — need implementation commits + PR or active worker |
| User message was `/execute-plan` | Not a request for a milestone report; resume `next_action` via tools |
| Cloud turn ended after a reply | Next message: `/execute-plan` or `resume-plan` on control issue — not permission-seeking |

**Phase merge is not session complete.** Merging phase *N* starts phase *N+1* in the same autonomy grant (memory §Phase boundaries).

---

## Evidence and testing (platform vs orchestrator)

| Generic testing instruction | During active execute-plan (gate `0`) |
|-----------------------------|----------------------------------------|
| Prove changes in the **user reply** | Put proof in **PR description**, **control issue** comments, and artifact files under `/opt/cursor/artifacts/` when the platform requires them |
| Manual UI walkthrough in chat | Run when UI changes; attach artifacts to PR / artifacts dir; **do not** end turn to narrate walkthrough |
| `code-tour-author-handoff.md` | Write when the turn changes product code; **not** a substitute for continuing the phase loop |

Orchestrator visibility explicitly **overrides** “show the user evidence each turn” for execute-plan sessions (skill §Orchestrator visibility).

---

## Phase implementation (orchestrator vs worker)

After prior phase **`merged`**:

| Orchestrator must (same session) | Forbidden |
|----------------------------------|-----------|
| Checkout next phase branch, `set-phase in_progress`, **implement** scoped work **or** spawn a **Task** phase worker and continue through PR + babysit+ after return | Stop after bootstrap commit + user-visible “PR-06 started” |
| Stay on babysit+ through squash-merge before advancing `set-phase merged` | Treat babysit+ “ends here” (§8 post-merge) as programme end — that scope is **pre-UAT polling only**, not multi-phase loop exit |

**Delegation:** At phase §3 Implement, spawn a fresh `generalPurpose` worker when the phase has non-trivial scope (typical for backend migrations, new routes, multi-file Flutter). The orchestrator may implement inline only if it will reach PR + babysit+ **without** sending a routine user chat stop. “When practical” means **default yes for R1+ implementation**, not “skip when large.”

---

## Babysit+ inside execute-plan

| Babysit+ completes | Execute-plan orchestrator |
|--------------------|---------------------------|
| Squash-merge of **phase** PR to integration | Record merge in runtime → **next phase** (no user chat checkpoint) |
| Squash-merge of **release** PR to `main` | `/babysit-uat` + pre-UAT watch → `complete-plan` |
| CI exhausted / `do-not-merge` | §Halt on control issue + short chat blocker alert |

Add to babysit+ PR triage comment when `plan_id` is set: `execute-plan: merge → continue phase loop per execute-plan-instruction-stack.md`.

---

## Cloud turn mechanics

1. **User-visible assistant messages end the Cloud turn** — design for long **tool-only** stretches during execute-plan.
2. **Valid user chat:** blocker alerts (one short paragraph + control issue link). **Invalid:** PR #, CI green, “next phase is…”, soft offers to continue.
3. If the platform ends the turn mid-phase, the **next** `/execute-plan` resumes `next_action`; the prior chat reply is **not** programme completion (plan markdown §Turn boundary).

---

## Related

| Doc | Role |
|-----|------|
| [execute-plan-schema.md](./execute-plan-schema.md) | Snapshot, integration `base_branch`, phases |
| [execute-plan-runtime.md](./execute-plan-runtime.md) | CLI gate, halt, resume |
| [pr-review-cost-efficiency.md](./pr-review-cost-efficiency.md) | Pre-PR self-review (still applies per phase PR) |
| [cursor-agent-framework.md](../engineering/cursor-agent-framework.md) | Tier-1 commands and Router |
