---
title: Organization domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,organization]
---

# Organization

Org identity, discovery, people & permissions, member privacy, branding — custody data model (not transfer workflows).

Part of the AgathaTrack domain-first documentation tree. Cross-cutting architecture: [/docs/architecture/index.md](/docs/architecture/index.md).

## On this domain

| Section | Link |
|---------|------|
| User journeys | [features/journeys.md](features/journeys.md) |
| Implementation specs | [features/specs.md](features/specs.md) |
| Plans index | [changes/plans.md](changes/plans.md) |
| Lessons index | [changes/lessons.md](changes/lessons.md) |
| Deferred work | [changes/deferred.md](changes/deferred.md) |

## Code map

| Layer | Path |
|-------|------|
| Flutter | `flutter_app/lib/features/organization/` |
| Node routes | `server/routes/organizations/` |
| Jest | `server/test/organizations/, orgConnections.test.js` |
| BDD | `organisation_profile.feature, organisation_discovery.feature, organisation_management.feature, organisation_member_privacy.feature, organisation_permissions.feature, admin_contacts.feature` |
| Playwright E2E | `organisation.profile.spec.ts, organisation.discovery.spec.ts, organisation.management.spec.ts` |
