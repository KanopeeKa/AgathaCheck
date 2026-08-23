---
title: Pipelines documentation index
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-23
tags: [pipelines,ci,cd,deploy]
---

# Pipelines (CI / CD / promotion)

Cross-cutting documentation for GitHub Actions, merge gates, UAT promotion, and deploy runbooks — **not** product-domain docs (those live under `docs/domains/`).

| Document | Purpose |
|----------|---------|
| [ci-cd-gates.md](./ci-cd-gates.md) | Blocking vs advisory CI gates, branch protection |
| [ci-cd-baseline.md](./ci-cd-baseline.md) | Pipeline metrics and performance targets |
| [ci-build-artifact-contract.md](./ci-build-artifact-contract.md) | Build artifact layout and contracts |
| [promotion-contract.md](./promotion-contract.md) | UAT → PROD promotion tags and rules |
| [e2e-ci-canary-plan.md](./e2e-ci-canary-plan.md) | PR Playwright canary initiative |
| [db-schema-bootstrap-plan.md](./db-schema-bootstrap-plan.md) | Database bootstrap for deploy environments |
| [uat-backend-node-modules-runbook.md](./uat-backend-node-modules-runbook.md) | UAT Passenger / `node_modules` recovery |

**E2E deploy tiers** (pre-UAT vs live smoke): [/docs/e2e/uat-deploy-tiers.md](/docs/e2e/uat-deploy-tiers.md)

**Sprint execution plans** (BDD/toolchain): [/docs/plans/README.md](/docs/plans/README.md)
