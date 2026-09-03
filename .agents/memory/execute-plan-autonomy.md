---
name: Execute-plan autonomy contract
description: When /execute-plan gate passes, proceed without permission prompts. Control issue for blockers; integration branch + per-phase workers for multi-phase plans.
---

## Green light

When `node scripts/execute_plan_runtime.js gate <plan_id>` exits **0** (`autonomy: active`, `autonomous-approved`, not revoked, `approved_until` in future):

- **Proceed** — implement, PR, babysit+, merge (`auto`), advance phases, resume after routine halts.
- **Do not ask** the human "shall I continue?" in chat.

## Cloud turn boundaries

Each agent **turn** ends when you respond — that is not a phase gate. Before ending a turn: commit, push, update PR/plan artifacts, comment on the control issue, state `next_action`. Continue the phase loop in the same session when possible; never use turn end as an excuse to ask permission. Soft closers ("let me know", "whenever you want", "I can start phase N on request") count as permission-seeking.

## User chat vs control issue

| Channel | Use for |
|---------|---------|
| **Control issue** | Canonical record: milestones, halts, `**Needs you:**` detail, resume steps |
| **User chat** | Routine brief status + what's next; **blocker alerts** (short ping + issue link — human sees chat first) |

**Handoff:** Shape the plan in chat → one-time grant (`approve-autonomous` or standing grant in snapshot) → `/execute-plan` runs without permission prompts until complete or a real blocker.

**Blocker dual-notify:** Post full detail on the control issue (`halt` / `**Needs you:**`), then a one-paragraph chat alert with issue # and the single action that unblocks you. Do not ask permission in chat for routine phase/PR/merge work.

## Follow-ups (during execute-plan)

| Kind | Action |
|------|--------|
| Small, in touched files, stability / tech-debt / correctness | Fix inline — do not ask |
| Larger or out-of-phase scope | Debt issue (`tech-debt`, `plan:<id>`) — continue current phase |
| Interesting but non-blocking | Bundle as questions at end of turn, or one follow-up issue |

## Conflicts between rules

| Situation | Action |
|-----------|--------|
| Goal unclear | Halt + `**Needs you:**` on control issue + short chat alert |
| Minor wording conflict, intention clear | Follow execute-plan snapshot; proceed |
| `replit-agent-operating-policy` "stop and ask" | **Does not apply** during active execute-plan except §Escalation |

## Low confidence (review triage)

Rare when phase `allowed_paths` and exit criteria are tight. Default: **debt issue + continue** — halt only when must-fix vs merge-safety is genuinely ambiguous.

## Session limit (24h)

After **~24 hours** of continuous work on the same plan (or approaching pod/session timeout): `halt --reason session_limit`, record `next_action`, post on control issue **and** short chat alert (`resume-plan <plan_id>` on the issue). No re-approve if still within `approved_until` (48h default).

## Phase workers vs UAT polling

| Spawn | Allowed? |
|-------|----------|
| Task sub-agent for **phase implementation** (one phase scope) | **Yes — recommended** at phase boundary |
| `/spawn-sprint-agents` when `spawn_allowed: true` | **Yes** |
| **UAT subagent** after merge (`agent-uat-babysit.sh`) | **No** — CI Pre-UAT owns promotion |
| Main session polling `deploy-uat` / prod-ready | **Never** |

Orchestrator owns: gate, runtime sync, babysit+, merge, next phase.

## Roadmap chaining (multi-plan grants)

When the standing grant names scope beyond the current `plan_id` ("entire plan/roadmap," "all phases," or explicit `/spawn-sprint-agents` for a wave), plan completion is **not** session completion:

- Auto-bootstrap the next slice's plan + snapshot and keep looping — do not close the turn with "let me know" / "whenever you want" / "say which wave and I'll bootstrap it." Those are soft-stops, not different from asking permission.
- Re-check for independent waves before slicing sequentially; use `/spawn-sprint-agents` when the human named it or you identify disjoint `allowed_paths`.
- Keep control-issue auditability per plan even when self-authorizing from a standing chat grant.

Full detail: `.cursor/skills/execute-plan/SKILL.md` §Roadmap chaining.

## Integration branch (2+ phases)

For multi-phase plans (especially UI / same product area): set snapshot `base_branch` to `cursor/<plan_id>-integration-<suffix>`. Phase PRs target integration; **one final PR** integration → `main` after all phases merged. Reduces repeated merges to `main` during the sprint.

Full skill: `.cursor/skills/execute-plan/SKILL.md`
