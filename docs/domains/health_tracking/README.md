---
title: Health tracking domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-08
tags: [domain,health_tracking]
---

# Health tracking

Medication and treatment entries, health issues, completion semantics, and reminders.

Part of the AgathaTrack domain-first documentation tree. Cross-cutting architecture: [/docs/architecture/index.md](/docs/architecture/index.md).

## Canonical capability

| Document | Contents |
|----------|----------|
| [specs.md](features/specs.md) | Requirements, journeys, scheduling/completion pointers to CSM and care-item evolution |

## In-flight

| Document | Role |
|----------|------|
| [plans.md](changes/plans.md) | Plans index |
| [deferred.md](changes/deferred.md) | Deferred work |

## Code map

| Layer | Path |
|-------|------|
| Flutter | `flutter_app/lib/features/health_tracking/` |
| Node routes | `server/routes/healthEntries/, healthIssues.js` |
| Jest | `healthEntries.test.js, healthIssues.test.js` |
| BDD | `health_tracking.feature` |
| Playwright E2E | `health.tracking.spec.ts` |
