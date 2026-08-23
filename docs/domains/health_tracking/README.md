---
title: Health tracking domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,health_tracking]
---

# Health tracking

Medication and treatment entries, health issues, completion semantics, and reminders.

Part of the AgathaTrack domain-first documentation tree. Cross-cutting architecture: [/docs/architecture/index.md](/docs/architecture/index.md).

## On this domain

| Section | Link |
|---------|------|
| User journeys | [features/journeys.md](features/journeys.md) |
| Implementation specs | [features/specs.md](features/specs.md) |
| Plans index | [changes/plans.md](changes/plans.md) |
| Deferred work | [changes/deferred.md](changes/deferred.md) |

## Code map

| Layer | Path |
|-------|------|
| Flutter | `flutter_app/lib/features/health_tracking/` |
| Node routes | `server/routes/healthEntries/, healthIssues.js` |
| Jest | `healthEntries.test.js, healthIssues.test.js` |
| BDD | `health_tracking.feature` |
| Playwright E2E | `health.tracking.spec.ts` |
