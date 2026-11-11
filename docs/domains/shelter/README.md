---
title: Shelter domain
owner: Documentation Team
audience: both
status: frozen
last_updated: 2026-09-07
tags: [domain,shelter,frozen]
---

# Shelter

> **Removed (2026-11):** Shelter product code was deleted from the app. Domain docs here are archival. Recovery tag and scope: [frozen-domains removal record](/docs/engineering/frozen-domains/README.md).

Shelter identity, discovery, people & permissions, member privacy, branding — custody data model (not transfer workflows). Product-facing term **Shelter** replaces legacy "Organisation" in docs; code paths remain `organization` until a dedicated migration.

Part of the AgathaTrack domain-first documentation tree. Cross-cutting architecture: [/docs/architecture/index.md](/docs/architecture/index.md).

## On this domain

| Section | Link |
|---------|------|
| User journeys | [features/journeys.md](features/journeys.md) |
| Implementation specs | [features/specs.md](features/specs.md) |
| Dashboard brief | [features/shelter-dashboard-brief.md](features/shelter-dashboard-brief.md) |
| Plans index | [changes/plans.md](changes/plans.md) |
| Deferred work | [changes/deferred.md](changes/deferred.md) |

## Code map

| Layer | Path |
|-------|------|
| Flutter | `flutter_app/lib/features/organization/` |
| Node routes | `server/routes/organizations/` |
| Jest | `server/test/organizations/, orgConnections.test.js` |
| BDD | `organisation_*.feature` (filenames unchanged) |
| Playwright E2E | `organisation.*.spec.ts` |
