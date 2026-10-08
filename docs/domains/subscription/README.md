---
title: Subscription domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-08
tags: [domain,subscription]
---

# Subscription

Premium tiers and billing integration (RevenueCat today; EU billing under review).

Part of the AgathaTrack domain-first documentation tree. Cross-cutting architecture: [/docs/architecture/index.md](/docs/architecture/index.md).

## Canonical capability

| Document | Contents |
|----------|----------|
| [specs.md](features/specs.md) | Requirements, journeys, tiers, RevenueCat, notifications cross-ref |

## In-flight

| Document | Role |
|----------|------|
| [plans.md](changes/plans.md) | Plans index |
| [deferred.md](changes/deferred.md) | Deferred work |

## Code map

| Layer | Path |
|-------|------|
| Flutter | `flutter_app/lib/features/subscription/` |
| Node routes | `—` |
| Jest | `—` |
| BDD | `subscriptions.feature` |
| Playwright E2E | `— (deferred until billing architecture decided)` |
