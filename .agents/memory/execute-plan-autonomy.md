---
name: Execute-plan autonomy contract
description: Pointer — gate 0 contract lives in AGENTS.md and execute-plan skill §Stop rules.
---

When `gate` exits **0**: [`AGENTS.md`](../../AGENTS.md) §Execute-plan · [execute-plan skill §Stop rules](../../.cursor/skills/execute-plan/SKILL.md) · [instruction stack](../../docs/agent-efficiency/execute-plan-instruction-stack.md).

Phase merge → next phase **same session**. Channels: control issue = telemetry/halts; user chat = blockers until `complete-plan`.

Preflight: checkout phase/integration branch before `gate`. Snag ladder: atomic-pr-policy. Unclear goal → halt; else snapshot wins.

v2 plans (`schema_version: 2`): [execute-plan-v2.md](../../docs/agent-efficiency/plans/execute-plan-v2.md) — `tick` decides; the rules above apply to v1.
