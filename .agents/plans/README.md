# Agent plans

Multi-phase autonomous work artifacts for `/execute-plan`.

| File | Purpose |
|------|---------|
| `<plan_id>.md` | Human-readable plan + runtime state (updated during run) |
| `<plan_id>.snapshot.json` | Frozen contract at upfront approval |

**Convention:** `artifact_branch_policy: phase-branch` — commit plan files on the active phase branch. Control issue is the index (see [github-labels.md](../../docs/agent-efficiency/github-labels.md)).

**Example:** `_example.md` + `_example.snapshot.json` (validated in CI via `scripts/validate_execute_plan_snapshot.js`).

**Docs:**

- [execute-plan skill](../../.cursor/skills/execute-plan/SKILL.md)
- [execute-plan-schema.md](../../docs/agent-efficiency/execute-plan-schema.md)
- [execute-plan-runtime.md](../../docs/agent-efficiency/execute-plan-runtime.md)
- [plan-template.md](../../docs/agent-efficiency/plan-template.md)
- [autonomous-pr-policy.md](../../docs/agent-efficiency/autonomous-pr-policy.md)

**Approval expiry:** 48 hours from `approved_at`. Re-approve if work exceeds window.
