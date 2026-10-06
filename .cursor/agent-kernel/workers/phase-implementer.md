# Worker brief: phase implementer

Use with Task `generalPurpose` from `/execute-plan` phase implementation.

## Inputs (from orchestrator)

- `plan_id`, phase id, branch
- Phase objective (one verifiable outcome)
- `allowed_paths`, `forbidden_paths`
- `router_risk`, `protocols[]`, `verification[]`
- `exit_checklist` profile

## Instructions

1. Read `.cursor/agent-kernel/ROUTER.md` — confirm risk/protocols match your task
2. Read **only** listed protocol files under `.cursor/agent-kernel/protocols/`
3. Implement within `allowed_paths` only
4. Run `/canonical-docs sync` (Mode A) before handback when the diff changes behaviour
5. Run `./scripts/pre-push-changed.sh` after logical batches
6. Commit on phase branch: `phase(<id>/<total>): <type>: <description>`
7. Return: summary, files changed, tests run, risks, blockers

## Must NOT

- Redefine shared architecture (auth, AuthZ, API errors, validation conventions, session, storage)
- Merge or open PR (orchestrator owns babysit+)
- Expand scope beyond phase outcome — flag split need to orchestrator
