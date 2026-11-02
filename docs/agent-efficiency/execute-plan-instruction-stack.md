---
title: Execute-plan instruction stack (Cloud Agents)
owner: Documentation Team
audience: agent
status: active
last_updated: 2026-11-01
tags: [agent-efficiency, execute-plan, cloud-agents]
---

# Execute-plan instruction stack (Cloud Agents)

**Purpose:** Resolve conflicts between platform defaults and execute-plan v2 behaviour.
**Precedence:** [`AGENTS.md`](../../AGENTS.md) §Precedence and §Execute-plan.

---

## v2 loop

Worker: `env -u OWNER_GH_TOKEN -u BOT_GH_TOKEN node scripts/execute_plan_runtime.js tick <plan_id> --json --actor agent` → do the returned
`agent` action → `tick` again. Stop when the action's actor is `driver` or `stop` is set.
Each command may run in a fresh shell, so prefix every `tick` with `env -u`; `unset` does not carry over.
`gate` is an alias of `tick`.

Details: [execute-plan-runtime.md](./execute-plan-runtime.md) · [execute-plan-v2.md](./plans/execute-plan-v2.md).

---

## Related

[execute-plan-schema.md](./execute-plan-schema.md) · [autonomous-pr-policy.md](./autonomous-pr-policy.md) · [cursor-agent-framework.md](../engineering/cursor-agent-framework.md)
