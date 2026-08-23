---
title: Cross-domain documentation
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-23
tags: [cross-domain]
---

# Cross-domain

Platform contracts and delivery work that spans multiple product domains.

| Folder | Contents |
|--------|----------|
| `features/` | Normative requirements shared across domains (when not in `docs/architecture/`) |
| `changes/` | Cross-domain delivery plans, program contract, delivery-process decisions, sprint execution plans |

## Key docs

| Doc | Purpose |
|-----|---------|
| [program-contract.md](changes/program-contract.md) | Experience-program vocabulary, notifications model, permissions scaffolding |
| [roadmap-delivery-plan.md](changes/roadmap-delivery-plan.md) | Phase R + 0–5 order and sprint breakdown |
| [delivery-decisions.md](changes/delivery-decisions.md) | Process decisions D32–D33 |

## Cross-cutting execution plans

Active and recent **multi-domain** execution plans (BDD sprints, toolchain, documentation waves). Domain-specific delivery plans live under `docs/domains/<domain>/changes/`.

| Plan | Focus | Status |
|------|-------|--------|
| [docs-domain-audit-63ad.md](changes/docs-domain-audit-63ad.md) | Full `.md` inventory and move/stay decisions | Complete (wave 3) |
| [documentation-consolidation-plan.md](changes/documentation-consolidation-plan.md) | Docs metadata and validation wave 1 | Complete |
| [sprint-6-execution-plan.md](changes/sprint-6-execution-plan.md) | BDD coverage sprint (org/foster/help) | Active remainder |
| [sprint-10-flutter-344-execution-plan.md](changes/sprint-10-flutter-344-execution-plan.md) | Flutter 3.44 / Dart 3.12 upgrade | In progress |

Domain-scoped execute-plan snapshots remain in `.agents/plans/` (link from domain `changes/plans.md` indexes).

Domain-specific decisions live under each domain's `features/*-decisions.md`. Index: [navigation README](/docs/domains/navigation/README.md#decision-index-split-from-experience-program-decisions-log).

Platform wire contracts (calendar dates, API reference) live under [/docs/architecture/](/docs/architecture/index.md).
