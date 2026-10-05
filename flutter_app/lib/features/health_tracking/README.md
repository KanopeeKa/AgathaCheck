---
title: Health tracking feature
owner: Pet Care team
status: active
component_id: flutter.feature.health_tracking
last_updated: 2026-10-05
last_reviewed: 2026-10-05
---

# Purpose

Health entries, issues, and documents for a pet. **Non-goals:** Care Item occurrence commands (see `care_item`).

## Public entrypoint

`package:pet_profile_app/features/health_tracking/health_tracking.dart`

## Public surface

| Symbol | Kind | Reason |
|--------|------|--------|
| `HealthEntry`, `HealthHistoryEntry` | domain entities | Lists and forms |
| `HealthRepository` | domain port | Tests and overrides |
| Create/update/delete/get use cases | domain commands | Orchestration |
| `healthProviders` | providers | Riverpod wiring |
| `HealthEntryFormScreen`, `HealthEntryCard` | UI | Cross-feature health UI |

## Dependencies

| Allowed | Forbidden |
|---------|-----------|
| `auth` public API, `core/` | Exporting or importing `data/` across features |

## Side effects & freshness

Remote-backed repositories; refresh providers after mutations.

## Permissions

Pet-scoped health APIs.

## Tests

`flutter_app/test/features/health_tracking/`
