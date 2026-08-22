---
title: Fostering domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,fostering]
---

# Fostering

Foster onboarding, placements, self-management, adoption, pet return — custody transfer workflows.

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
| Flutter | `flutter_app/lib/features/organization/ (foster flows)` |
| Node routes | `fosterPlacements.js, custodyTransfers.js` |
| Jest | `fosterPlacements.test.js, custodyTransfers.test.js` |
| BDD | `foster_onboarding.feature, foster_self_management.feature, fostering_platform.feature, org_foster_and_adoption.feature, org_pet_return.feature` |
| Playwright E2E | `adoption.spec.ts, organisation.pet.management.spec.ts` |
