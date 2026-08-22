---
title: Pet profiles domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,pet_profile]
---

# Pet profiles

Pet CRUD, guardian dashboard views, sharing sections on pet detail, and pet timeline.

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
| Flutter | `flutter_app/lib/features/pet_profile/` |
| Node routes | `server/routes/pets/` |
| Jest | `server/test/pets/` |
| BDD | `pet_profiles.feature` |
| Playwright E2E | `pet.profiles.spec.ts` |
