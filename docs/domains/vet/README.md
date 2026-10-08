---
title: Veterinarians domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-08
tags: [domain,vet]
---

# Veterinarians

Vet contact CRUD, linking vets to pets, and vet list navigation.

Part of the AgathaTrack domain-first documentation tree. Cross-cutting architecture: [/docs/architecture/index.md](/docs/architecture/index.md).

## Canonical capability

| Document | Contents |
|----------|----------|
| [specs.md](features/specs.md) | Requirements, journeys, data model, People migration note |

## In-flight

| Document | Role |
|----------|------|
| [plans.md](changes/plans.md) | Plans index |
| [deferred.md](changes/deferred.md) | Deferred work |

## Code map

| Layer | Path |
|-------|------|
| Flutter | `flutter_app/lib/features/vet/` |
| Node routes | `server/routes/vets.js` |
| Jest | `vets.test.js` |
| BDD | `veterinarian_management.feature` |
| Playwright E2E | `—` |
