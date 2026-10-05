---
title: Pet profile feature
owner: Pet Care team
status: active
component_id: flutter.feature.pet_profile
last_updated: 2026-10-05
last_reviewed: 2026-10-05
---

# Purpose

Pet CRUD, list, profile cards, and manage-events surfaces. **Non-goals:** shell navigation (`experience`) or care occurrence commands (`care_item`).

## Public entrypoint

`package:pet_profile_app/features/pet_profile/pet_profile.dart`

## Public surface

| Symbol | Kind | Reason |
|--------|------|--------|
| `Pet` | domain entity | Shared pet model |
| `PetRepository` | domain port | Tests |
| Add/update/delete/get use cases | domain commands | Orchestration |
| `petProviders` | providers | Pet list and selection |
| `PetListScreen`, `PetFormScreen`, `PetCard` | UI | Router and embedding |

## Dependencies

| Allowed | Forbidden |
|---------|-----------|
| Public entrypoints of `experience`, `care_taxonomy`, etc. (migration in I1) | Direct `data/` imports |

## Side effects & freshness

Remote pet list; invalidate on mutation.

## Permissions

Owner/shared pet access per API.

## Tests

`flutter_app/test/features/pet_profile/`
