---
title: People feature
owner: Pet Care team
status: active
component_id: flutter.feature.people
last_updated: 2026-10-06
last_reviewed: 2026-10-06
---

# Purpose

Care team roster, contacts, and people hub flows. **Non-goals:** veterinarian clinical records (`vet`).

## Public entrypoint

`package:pet_profile_app/features/people/people.dart`

## Public surface

| Symbol | Kind | Reason |
|--------|------|--------|
| `PeopleContact`, `PersonRosterEntry` | domain entities | Lists and detail |
| `peopleProviders` | providers | Roster state |
| People hub, list, detail, add, edit screens | UI screens | Router destinations |
| `PeopleLegacyVetRedirectScreen` | UI screen | Compatibility redirect |

## Dependencies

| Allowed | Forbidden |
|---------|-----------|
| `auth`, `core/` public surfaces | Other features' `data/` |

## Side effects & freshness

Remote roster; invalidate providers after edits.

## Permissions

Pet/household-scoped people APIs.

## Tests

`flutter_app/test/features/people/`
