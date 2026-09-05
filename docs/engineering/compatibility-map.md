---
title: Cursor framework compatibility map
owner: Documentation Team
audience: agent
status: active
last_updated: 2026-09-05
tags: [agent, engineering, cursor]
---
# Cursor framework — compatibility map (v2 rollout)

Inventory of existing agent artifacts and how the Engineering Router framework relates to each. Created during `cursor-engineering-framework-v2` implementation.

---

## Preserved (unchanged role)

| Artifact | Owns |
|----------|------|
| `execute_plan_runtime.js` | Gate, halt, resume, phase state, snapshots |
| `autonomous-pr-policy.md` | PR triage, debt, merge gates, escalation |
| `phase-exit-checklists.md` | Executable exit profiles (now maps to protocol IDs) |
| `atomic-pr.mdc` | One-outcome PRs, snag ladder |
| `pr-hygiene.mdc` | Pre-PR critical self-review |
| `agent-coordination.mdc` | Parallel agents, integration branches |
| `merge-policy.mdc` | Branch naming, rebase before push |
| `modularity.mdc` | 500-line limit |
| `babysit_*.sh`, `e2e_debug_*.mjs` | UAT/remedial automation |
| Tier 1 skills (5) | User-facing workflows — **patched** with Router preamble |

---

## Consolidated (guidance moves to protocols)

| Former artifact | Canonical protocol / rule |
|-----------------|---------------------------|
| `security-error-audit` skill | `protocols/security.md` §5xx audit |
| `single-backend-route-change` skill | `protocols/api-contract.md` + `validation.md` |
| `ui-check` skill | `protocols/accessibility.md` §Quick pass |
| `security.mdc` (expanded topics) | `protocols/security.md` + slim `security.mdc` |
| `testing.mdc` (depth) | `protocols/testing.md` + slim `testing.mdc` |

Tier 3 skills remain as **internal/deprecated** stubs until references migrate.

---

## Tier taxonomy (post-rollout)

### Tier 1 — user-facing

`/execute-plan` · `/babysit-plus` · `/babysit-uat` · `/e2e-debug` · `/ui-design-deep`

### Tier 2 — orchestrator/internal

`/spawn-sprint-agents` · `/pre-push-verify` · `/dependabot-batch` · `/split-flutter-screen` · `/add-bdd-playwright-scenario`

### Tier 3 — merged into protocols (do not user-invoke)

`/ui-check` · `/single-backend-route-change` · `/security-error-audit`

---

## New artifacts

| Path | Role |
|------|------|
| `.cursor/agent-kernel/ROUTER.md` | Classification + protocol resolution |
| `.cursor/agent-kernel/protocols/*.md` | Selective engineering procedures |
| `.cursor/agent-kernel/workers/*.md` | Task sub-agent brief templates |
| `.cursor/rules/pet-care-architecture.mdc` | Path-scoped Pet Care boundaries |
| `docs/engineering/cursor-agent-framework.md` | Human + agent framework guide |
| `docs/engineering/router-scenarios.md` | Routing acceptance fixtures |

---

## Deferred

- `scripts/router_resolve.js` — optional snapshot metadata helper  
- Snapshot fields `router_risk`, `protocols[]` — textual annotations first  
- `/release-gate` skill — use `release-verification` protocol instead
