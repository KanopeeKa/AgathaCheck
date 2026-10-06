---
title: Sharing feature
owner: Pet Care team
status: active
component_id: flutter.feature.sharing
last_updated: 2026-10-06
last_reviewed: 2026-10-06
---

# Purpose

Pet sharing, households, invites, and shared-pet access UI. **Non-goals:** auth account creation.

## Public entrypoint

`package:pet_profile_app/features/sharing/sharing.dart`

## Public surface

| Symbol | Kind | Reason |
|--------|------|--------|
| Share/household domain entities | domain | Invite and access models |
| `SharingRepository`, `HouseholdRepository` | domain ports | Tests |
| Share/household providers | providers | Invite flows |
| Share, shared pet, households, invite landing screens | UI screens | Router destinations |

## Dependencies

| Allowed | Forbidden |
|---------|-----------|
| `auth`, `pet_profile` entrypoints, `core/` | Cross-feature `data/` |

## Side effects & freshness

Invite and access mutations refresh providers.

## Permissions

Sharing and household APIs.

## Tests

`flutter_app/test/features/sharing/`
