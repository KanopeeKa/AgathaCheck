---
title: Weight tracking domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-08
tags: [domain,weight_tracking]
---

# Weight tracking

Weight entry history, charts, weigh-in fulfilment, and profile integration.

Part of the AgathaTrack domain-first documentation tree. Cross-cutting architecture: [/docs/architecture/index.md](/docs/architecture/index.md).

## Canonical capability

| Document | Role |
|----------|------|
| [weight-monitoring-model.md](features/weight-monitoring-model.md) | Product/API model, user journeys, implementation reference, deferred work |

## Code map

| Layer | Path |
|-------|------|
| Flutter | `flutter_app/lib/features/weight_tracking/` |
| Node routes | `server/routes/weightEntries.js` (→ modular `server/routes/weightEntries/` in WEIGHT A) |
| Care link | `server/lib/care/observations/`, occurrence commands |
| Jest | `server/test/weightEntries.test.js`, `server/test/healthEntries/completeWeight.test.js` |
| BDD | `weight_tracking.feature` |
| Playwright E2E | `weight.tracking.spec.ts`, `weight.hub.spec.ts` (WEIGHT B) |
