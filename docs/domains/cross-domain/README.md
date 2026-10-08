---
title: Cross-domain documentation
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-08
tags: [cross-domain]
---

# Cross-domain

Platform contracts and delivery work that spans multiple product domains.

| Folder | Contents |
|--------|----------|
| `features/` | Programme contract, delivery index, normative cross-cutting requirements |
| `changes/` | Active multi-domain execution plans (BDD sprints, etc.) |

## Key docs

| Doc | Purpose |
|-----|---------|
| [program-contract.md](features/program-contract.md) | Experience-program vocabulary, notification/permission targets, test strategy |
| [delivery-plans-index.md](features/delivery-plans-index.md) | Phase order (D32–D33), programme index, migration handover pointer |
| [terminology.md](/docs/design/terminology.md) | Pet Care + Experience program vocabulary for copy and agents |

## Cross-cutting execution plans

| Plan | Focus | Status |
|------|-------|--------|
| [sprint-6-execution-plan.md](changes/sprint-6-execution-plan.md) | BDD coverage sprint (org/foster/help) | In delivery |
| [documentation-migration-handover.md](/docs/domains/documentation/changes/documentation-migration-handover.md) | Canonical-docs migration waves | In delivery |

Domain-scoped execute-plan snapshots remain in `.agents/plans/` (link from domain `changes/plans.md` indexes).

Domain-specific decisions live under each domain's `features/*-decisions.md`. Index: [navigation README](/docs/domains/navigation/README.md#decision-index-split-from-experience-program-decisions-log).

Platform wire contracts (calendar dates, API reference) live under [/docs/architecture/](/docs/architecture/index.md).
