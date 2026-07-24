---
name: Execute-plan autonomy contract
description: When /execute-plan gate passes, proceed without permission prompts. Control issue for blockers; integration branch + per-phase workers for multi-phase plans.
---

## Green light

When `node scripts/execute_plan_runtime.js gate <plan_id>` exits **0** (`autonomy: active`, `autonomous-approved`, not revoked, `approved_until` in future):

- **Proceed** — implement, PR, babysit+, merge (`auto`), advance phases, resume after routine halts.
- **Do not ask** the human "shall I continue?" in chat.

## User chat vs control issue

| Channel | Use for |
|---------|---------|
| **Control issue** | Milestones, halts, `**Needs you:**` blockers, `session_limit` checkpoints |
| **User chat** | Brief status + what's next. Optional bundled follow-up questions **at end of turn only** — never as a flow break |

## Follow-ups (during execute-plan)

| Kind | Action |
|------|--------|
| Small, in touched files, stability / tech-debt / correctness | Fix inline — do not ask |
| Larger or out-of-phase scope | Debt issue (`tech-debt`, `plan:<id>`) — continue current phase |
| Interesting but non-blocking | Bundle as questions at end of turn, or one follow-up issue |

## Conflicts between rules

| Situation | Action |
|-----------|--------|
| Goal unclear | Halt + `**Needs you:**` on control issue |
| Minor wording conflict, intention clear | Follow execute-plan snapshot; proceed |
| `replit-agent-operating-policy` "stop and ask" | **Does not apply** during active execute-plan except §Escalation |

## Low confidence (review triage)

Rare when phase `allowed_paths` and exit criteria are tight. Default: **debt issue + continue** — halt only when must-fix vs merge-safety is genuinely ambiguous.

## Session limit (24h)

After **~24 hours** of continuous work on the same plan (or approaching pod/session timeout): `halt --reason session_limit`, record `next_action`, post on control issue. Human comments `resume-plan <plan_id>` — no re-approve if still within `approved_until` (48h default).

## Phase workers vs UAT polling

| Spawn | Allowed? |
|-------|----------|
| Task sub-agent for **phase implementation** (one phase scope) | **Yes — recommended** at phase boundary |
| `/spawn-sprint-agents` when `spawn_allowed: true` | **Yes** |
| Task sub-agent to **poll UAT / prod-ready** | **Never** — enqueue + exit |

Orchestrator owns: gate, runtime sync, babysit+, merge, UAT enqueue, next phase.

## Integration branch (2+ phases)

For multi-phase plans (especially UI / same product area): set snapshot `base_branch` to `cursor/<plan-id>-integration-<suffix>`. Phase PRs target integration; **one final PR** integration → `main` after all phases merged. Reduces repeated merges to `main` during the sprint.

Full skill: `.cursor/skills/execute-plan/SKILL.md`
