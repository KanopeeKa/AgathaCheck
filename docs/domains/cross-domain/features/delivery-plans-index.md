---
title: Cross-domain programme index
owner: Documentation Team
audience: agent
domain: cross-domain
feature_id: delivery_plans_index
status: active
last_updated: 2026-10-07
related_prs: []
---

# Cross-domain programme index

Normative product requirements for cross-cutting capabilities live in domain `features/` or `docs/architecture/` / `docs/design/`. This file indexes **delivery and programme** material under `changes/`.

| Doc | Purpose |
|-----|---------|
| [program-contract.md](../changes/program-contract.md) | Experience-program vocabulary and cross-cutting contracts |
| [roadmap-delivery-plan.md](../changes/roadmap-delivery-plan.md) | Phase order and sprint breakdown |
| [delivery-decisions.md](../changes/delivery-decisions.md) | Process decisions D32–D33 |
| [docs-domain-audit-63ad.md](../changes/docs-domain-audit-63ad.md) | Historical inventory (complete) |

**Documentation migration:** authoritative handover is [documentation-migration-handover.md](/docs/domains/documentation/changes/documentation-migration-handover.md). The Aug 2025 cross-domain consolidation plan was retired in Wave 0 (file deleted).

## Requirements

| ID | Rule | Status |
|----|------|--------|
| DELIVERY-PLANS-INDEX-R-001 | Agents use the documentation migration handover for consolidate waves, not superseded cross-domain consolidation plans | Live |

## Acceptance criteria

| Given / When / Then | Requirement | Coverage |
|---------------------|-------------|----------|
| Given an agent is asked to migrate domain docs, when they search for a consolidation plan, then they open `documentation-migration-handover.md` | DELIVERY-PLANS-INDEX-R-001 | test: scripts/check_docs_canonical.test.js#R-A4 fold before delete |

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
|----|----------|-----------|--------|------|-----|
| DELIVERY-PLANS-INDEX-D-001 | Retire `documentation-consolidation-plan.md` in favour of documentation-domain migration handover | Single authoritative migration plan; avoids duplicate 2025 three-PR strategy | Live | 2026-10-07 | TBD |
