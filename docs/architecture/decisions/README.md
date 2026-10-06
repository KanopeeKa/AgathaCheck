---
title: Architecture decision records
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-06
tags: [architecture, adr]
---

# Architecture decision records (ADR)

Short, durable decisions that outlive individual PRs. New ADRs use the next four-digit number and live in this directory.

| ADR | Title | Status |
|-----|-------|--------|
| [0001](./0001-account-erasure-acceptance.md) | Account erasure acceptance boundary | Accepted |
| [0002](./0002-feature-layering.md) | Feature layering and dependency direction (Flutter) | Accepted |
| [0003](./0003-transaction-ownership.md) | Server transaction ownership (`withTransaction`, COMMIT guard) | Accepted |
| [0004](./0004-cleanup-jobs.md) | Minimal cleanup jobs (D10 / D11, lease, retention) | Accepted |
| [0005](./0005-canonical-health-state-care-schedule-controller.md) | Canonical health state and `CareScheduleController` (D19) | Accepted |
| [0006](./0006-frozen-data-compatibility-seam.md) | Frozen-data compatibility seam (Package 2) | Accepted |
| [0007](./0007-pet-cache-freshness.md) | Pet list cache freshness (D2 / D18) | Accepted |

## When to add an ADR

- Cross-cutting behaviour that multiple routes, jobs, or clients must honour.
- Irreversible or privacy-critical commitments (erasure, retention, auth).
- Batch programme exit gates referenced from roadmap docs.

For product-domain decisions, prefer `docs/domains/*/features/*-decisions.md`; use ADRs for platform and compliance boundaries.
