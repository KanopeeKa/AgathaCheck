---
title: Vet feature
owner: Pet Care team
status: active
component_id: flutter.feature.vet
last_updated: 2026-10-06
last_reviewed: 2026-10-06
---

# Purpose

Veterinarian roster, forms, and team cards for a pet. **Non-goals:** people roster (`people`).

## Public entrypoint

`package:pet_profile_app/features/vet/vet.dart`

## Public surface

| Symbol | Kind | Reason |
|--------|------|--------|
| `Vet` | domain entity | Shared vet model |
| `VetRepository` | domain port | Tests |
| Vet CRUD use cases | domain commands | Orchestration |
| `vetProviders` | providers | Vet list state |
| `VetListScreen`, `VetFormScreen` | UI screens | Router destinations |

## Dependencies

| Allowed | Forbidden |
|---------|-----------|
| `auth`, `core/` | Exporting or cross-importing `data/` |

## Side effects & freshness

Remote vet list per pet; invalidate on mutation.

## Permissions

Pet-scoped vet APIs.

## Tests

`flutter_app/test/features/vet/`
