---
title: Pet tags feature
owner: Pet Care team
status: active
component_id: flutter.feature.pet_tags
last_updated: 2026-10-06
last_reviewed: 2026-10-06
---

# Purpose

Pet tag definitions, filters, and manage-tags UI. **Non-goals:** pet profile core fields.

## Public entrypoint

`package:pet_profile_app/features/pet_tags/pet_tags.dart`

## Public surface

| Symbol | Kind | Reason |
|--------|------|--------|
| `PetTag` | domain entity | Tag model |
| `PetTagRepository` | domain port | Tests |
| `PetTagFilter` | domain service | Filtering |
| `petTagProviders` | providers | Tag state |
| `ManagePetTagsScreen` | UI screen | Router destination |

## Dependencies

| Allowed | Forbidden |
|---------|-----------|
| `auth`, `core/` | Cross-feature `data/` |

## Side effects & freshness

Remote tags; refresh after edits.

## Permissions

Pet-scoped tag APIs.

## Tests

`flutter_app/test/features/pet_tags/`
