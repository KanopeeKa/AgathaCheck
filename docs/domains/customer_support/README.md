---
title: Customer support domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-11-11
tags: [domain, customer_support, support]
---

# Customer support

Native **help, support, and (future) automated bug resolution** for AgathaTrack pet parents. This domain is **not** the [People](/docs/domains/people/README.md) **directory contact** model (`/api/people/contacts`).

Part of the AgathaTrack domain-first documentation tree. Cross-cutting architecture: [/docs/architecture/index.md](/docs/architecture/index.md).

## Programme

| Document | Role |
|----------|------|
| [support-roadmap.md](changes/support-roadmap.md) | **Proposed** phased delivery (Phases 1–5), architecture, vendors, security rules |
| [plans.md](changes/plans.md) | GitHub phase issues and execute-plan handoff index |

## Canonical capabilities (requirements)

| Phase | Capability | Document | Status |
|-------|------------|----------|--------|
| 1 | Contact hub and ticketing | [support-ticketing.md](features/support-ticketing.md) | Planned |
| 2 | Observability for support evidence | [support-observability.md](features/support-observability.md) | Planned |
| 3 | Temporary diagnostic sessions | [support-diagnostics.md](features/support-diagnostics.md) | Planned |
| 4 | AI triage and GitHub linkage | [support-triage.md](features/support-triage.md) | Planned |
| 5 | Agent investigation and release feedback | [support-automation.md](features/support-automation.md) | Planned |

## Related domains

| Domain | Relationship |
|--------|----------------|
| [Help & about](/docs/domains/help_about/README.md) | FAQ and about; support **hub** and tickets live here |
| [People](/docs/domains/people/README.md) | Directory **contacts** (vets, sitters) — separate product concept |
| [Auth](/docs/domains/auth/README.md) | Ticket access control; erasure/export boundaries |
| [Notifications](/docs/domains/notifications/README.md) | In-app feed distinct from transactional support email |
| Platform | [Observability](/docs/ops/observability.md), PostHog, mail transport |

## Code map (target — not implemented)

| Layer | Path | Notes |
|-------|------|-------|
| Flutter | `flutter_app/lib/features/support/` (TBD) | Contact hub, form, ticket history |
| Node routes | `server/routes/support/` (TBD) | Tickets, attachments, admin |
| Migrations | `db/migrations/` (TBD) | `support_*` tables |
| Jest | `server/test/support/` (TBD) | |
| BDD | TBD | e.g. `customer_support.feature` |
| Playwright E2E | TBD | |

**Today:** Account → Contact opens `mailto:contact@agathatrack.com` (`DrawerMenuConfig.contactEmail`).

## Tests and documentation

BDD, Jest, and E2E coverage are **TBD** until each phase ships. Acceptance criteria cite `none — #<phase-issue>` until BDD/Jest/E2E are wired (see [plans.md](changes/plans.md)).
