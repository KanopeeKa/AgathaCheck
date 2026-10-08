---
title: Delivery process decisions
owner: Documentation Team
status: in-delivery
status_since: 2026-10-08
tags: [cross-domain, decisions, delivery]
folds_into: docs/domains/cross-domain/features/delivery-plans-index.md
plan: documentation-migration-514a
---

# Cross-domain delivery — locked decisions

Process decisions for phase ordering and merge policy (D32–D33). Product behaviour decisions live in domain `features/*-decisions.md`.

---

## H — Delivery process

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D32** | A dedicated **Phase R (Reconciliation)** runs before Phase 0, closing out D2/D6 and tagging affected BDD scenarios `@legacy` per the existing G0 §14.2 pattern. | locked | Phase R |
| **D33** | Default delivery mode is **single-agent, sequential, direct-to-`main` per phase** (merge-policy.mdc "single-agent / single-domain PRs → main"). `/spawn-sprint-agents` stays available as an option for any phase where disjoint-path parallelism is later judged worthwhile (e.g. Phase 3 admin-contacts vs pet-tabs), but is not the default plan. | locked | All |

---

## How to use

- Phase order and sprint breakdown: [roadmap-delivery-plan.md](roadmap-delivery-plan.md)
- Phase R close-out: [navigation-decisions.md — Phase R](/docs/domains/navigation/features/navigation-decisions.md#phase-r-reconciliation-folded)
- Platform contract: [program-contract.md](program-contract.md)
