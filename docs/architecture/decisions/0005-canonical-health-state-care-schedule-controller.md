---
title: "ADR 0005: Canonical health state and CareScheduleController (D19)"
owner: Mobile / Architecture
audience: both
status: accepted
last_updated: 2026-10-06
tags: [architecture, flutter, health, adr]
adr: 0005
programme: active-codebase-batch-g-client-authority-e41f
---

# ADR 0005: Canonical health state and CareScheduleController (D19)

## Status

**Accepted** — 2026-10-06 (Batch K phase 3). Implemented in Batch G phases 2–3.

## Context

Health entries were loaded from many widgets via direct repository calls. Failed refreshes could wipe the store, and users could see a failed command when the server had already committed (review Package 8, roadmap **D19**).

## Decision

### Canonical store

- One Riverpod source of truth: `healthEntriesNotifierProvider` holds the full entry list; per-pet and per-entry views are **selectors** over that store (no duplicate caches).
- `refresh()` on failure **retains** the last good `AsyncValue` data and surfaces error state separately where required by tests.

### CareScheduleController

- Location: `flutter_app/lib/features/health_tracking/presentation/controllers/care_schedule_controller.dart`.
- Owns all care **mutations**: complete/skip/reschedule occurrences, weight completion, issue link/unlink, and related reconciliation.
- Widgets call the controller; presentation widgets do not call `HealthRepository` directly (enforced by `health_presentation_boundary_test.dart`).
- Each command returns `CommandOutcome { committed, refreshFailed }`:
  - `committed: true` when the API succeeded.
  - `refreshFailed: true` when commit succeeded but canonical refresh failed — UI shows recovery affordance, not a false failure.
- In-flight deduplication per occurrence key prevents double-submit.

### Non-goals

- Optimistic UI that assumes success before the server responds.
- A second health cache in `pet_care` or `experience` — they read selectors or invalidate via the controller.

## Consequences

- New health mutations must extend `CareScheduleController` and update reconciliation in one place.
- E2E semantics and API contracts remain authoritative (`docs/architecture/openapi/pet-care-critical.json`).
- Server occurrence commands stay in `server/routes/healthEntries/` and `server/lib/care/**`; this ADR is client authority only.

## References

- Roadmap D19: `.agents/plans/active-codebase-completion-e41f.md`
- Batch G: `.agents/plans/active-codebase-batch-g-client-authority-e41f.md`
- Component: [health_tracking README](../../../flutter_app/lib/features/health_tracking/README.md)
- Server: [server/routes/healthEntries/README.md](../../../server/routes/healthEntries/README.md)
