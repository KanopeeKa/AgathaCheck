---
title: Weight tracking domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,weight_tracking]
---

# Weight tracking

Weight entry history, charts, and profile integration for monitoring pet growth.

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
| Flutter | `flutter_app/lib/features/weight_tracking/` |
| Node routes | `server/routes/weightEntries.js` |
| Jest | `weightEntries.test.js` |
| BDD | `weight_tracking.feature` |
| Playwright E2E | `weight.tracking.spec.ts` |
