---
name: Execute-plan autonomy contract
description: When /execute-plan gate passes, proceed without permission prompts. Run-until-blocked; control issue for blockers only.
---

## Green light

When `node scripts/execute_plan_runtime.js gate <plan_id>` exits **0** (`autonomy: active`, `autonomous-approved`, not revoked, `approved_until` in future):

- **Run-until-blocked** — implement, PR, babysit+, merge, advance phases without stopping for milestones or turn boundaries
- **Do not ask** the human "shall I continue?" in chat
- **`/execute-plan` without id** — infer plan from conversation, branch, control issue, or single `busy` issue (skill §Resolve plan_id)

## Default mode: run-until-blocked

Stop only when:

1. Phase **merge-done** (+ pre-UAT green on final main PR) → next phase or `complete-plan`
2. **`complete-plan`** finished
3. **§Halt / §Escalation** (including `session_limit` ~24h — the only routine checkpoint)
4. Pod hard stop → `halt --reason session_limit`; human `resume-plan` on control issue

**Not stop points:** PR opened, CI green, control-issue milestone, worker returned, e2e-debug opened remedial PR. Continue in-loop; e2e-debug **must** chain `/babysit-uat` same session.

## Cloud turns

Prefer long tool-only stretches before any user-visible reply. Control-issue milestones are **telemetry**, not session boundaries. If the platform ends the turn mid-phase, next session: `/execute-plan` (no id) or `resume-plan` on the issue — never permission-seeking chat.

## User chat vs control issue

| Channel | Use for |
|---------|---------|
| **Control issue** | Milestones (telemetry), halts, `**Needs you:**` detail, resume steps |
| **User chat** | **Blocker alerts only** — short ping + issue link when §Halt |

Do not send routine progress summaries that end the turn mid-phase.

## Resolve plan_id (no explicit id)

1. This conversation / linked control issue
2. Checked-out branch → snapshot on that branch
3. `plan:<id>` label on control issue
4. Roadmap → `roadmap-next-child`
5. Single open `busy` + `autonomous-approved` execute-plan issue

Multiple matches → `**Needs you:**` on control issue; do not guess.

## Preflight artifact branch

Checkout phase or integration branch **before** `gate` — `.agents/plans/<plan_id>.snapshot.json` may not exist on `main`.

## Follow-ups (during execute-plan)

| Kind | Action |
|------|--------|
| Small, in touched files, stability / tech-debt / correctness | Fix inline — do not ask |
| Larger or out-of-phase scope | Debt issue — continue current phase |
| Interesting but non-blocking | Debt issue or bundle **after** plan complete — do not pause |

## Conflicts between rules

| Situation | Action |
|-----------|--------|
| Goal unclear | Halt + `**Needs you:**` on control issue + short chat alert |
| Minor wording conflict, intention clear | Follow execute-plan snapshot; proceed |
| `replit-agent-operating-policy` "stop and ask" | **Does not apply** during active execute-plan except §Escalation |

Full skill: `.cursor/skills/execute-plan/SKILL.md`
