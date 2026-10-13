---
name: Execute-plan autonomy contract
description: When /execute-plan gate passes, proceed without permission prompts. Run-until-blocked; control issue for blockers only.
---

## Green light

When `node scripts/execute_plan_runtime.js gate <plan_id>` exits **0**: follow **§Stop rules** in `.cursor/skills/execute-plan/SKILL.md` (valid stops, not-stops, user chat). Instruction precedence: `docs/agent-efficiency/execute-plan-instruction-stack.md`.

- **`/execute-plan` without id** — skill §Resolve plan_id

## Phase boundaries

Merging phase N → implement phase N+1 **same session** (skip only explicit blockers). Anti-patterns: chat milestone then reply; plan-only commit then end; "what's next" without tools.

**Owner merge:** babysit+ squash-merge when CI green under full autonomous grant.

## Channels

| Channel | Use |
|---------|-----|
| Control issue | Milestones, halts, `**Needs you:**`, resume steps |
| User chat | Blocker alerts only until `complete-plan` |

## Preflight

Checkout phase/integration branch before `gate` — snapshot may not be on `main`.

## Follow-ups

Small in-touched-files fixes inline. Larger → debt issue + continue phase. Non-blocking → debt or post-`complete-plan` bundle.

## Conflicts

Unclear goal → halt. Minor wording vs clear intent → snapshot wins. Full skill + policy: `.cursor/skills/execute-plan/SKILL.md` · `docs/agent-efficiency/autonomous-pr-policy.md` §Execute-plan overrides.
