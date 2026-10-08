---
title: Pet profiles domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-08
tags: [domain,pet_profile]
---

# Pet profiles

Pet CRUD, guardian dashboard views, sharing sections on pet detail, pet timeline, tags, and org activity sorting.

Part of the AgathaTrack domain-first documentation tree. Cross-cutting architecture: [/docs/architecture/index.md](/docs/architecture/index.md).

## Canonical capabilities

| Capability | Document |
|------------|----------|
| Decisions (D17–D24, D34–D38), journeys, implementation reference, pet tags v1 | [pet-profile-decisions.md](features/pet-profile-decisions.md) |
| Pet activity model (org preview / sort) | [pet-activity-model.md](features/pet-activity-model.md) |
| Pet Care dashboard locked brief | [guardian-dashboard-brief.md](features/guardian-dashboard-brief.md) |

## In-flight / related delivery

| Document | Role |
|----------|------|
| [guardian-today-contract.md](changes/guardian-today-contract.md) | Pet Care home / Today (Wave 3.2) |
| [phase-2-guardian-journey.md](changes/phase-2-guardian-journey.md) | Phase 2 guardian journey delivery |
| [plans.md](changes/plans.md) | Plans index |

## Code map

| Layer | Path |
|-------|------|
| Flutter | `flutter_app/lib/features/pet_profile/` |
| Node routes | `server/routes/pets/` |
| Pet activity writes | `server/lib/petActivity.js` |
| Jest | `server/test/pets/` |
| BDD | `pet_profiles.feature` |
| Playwright E2E | `pet.profiles.spec.ts` |
