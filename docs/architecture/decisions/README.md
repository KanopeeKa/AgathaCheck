---
title: Architecture decision records
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-04
tags: [architecture, adr]
---

# Architecture decision records (ADR)

Short, durable decisions that outlive individual PRs. New ADRs use the next four-digit number and live in this directory.

| ADR | Title | Status |
|-----|-------|--------|
| [0001](./0001-account-erasure-acceptance.md) | Account erasure acceptance boundary | Accepted |

## When to add an ADR

- Cross-cutting behaviour that multiple routes, jobs, or clients must honour.
- Irreversible or privacy-critical commitments (erasure, retention, auth).
- Batch programme exit gates referenced from roadmap docs.

For product-domain decisions, prefer `docs/domains/*/features/*-decisions.md`; use ADRs for platform and compliance boundaries.
