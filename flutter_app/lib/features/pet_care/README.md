---
title: Pet Care feature
owner: Pet Care team
status: active
component_id: flutter.feature.pet_care
last_updated: 2026-10-05
last_reviewed: 2026-10-05
---

# Purpose

Pet Care temporal grouping, agenda presentation helpers, and planned-absence flows. **Non-goals:** global shell layout (`experience`) or health entry authoring.

## Public entrypoint

`package:pet_profile_app/features/pet_care/pet_care.dart`

## Public surface

| Symbol | Kind | Reason |
|--------|------|--------|
| `CareTemporalGroup`, buckets, grouping service | domain | Agenda grouping |
| `careTemporalGroupingProviders`, `petCarePresentationProviders` | providers | Desk modules |
| Planned absence hub/flow/plan/edit screens | UI screens | Router (`away_routes`) |
| `AbsenceInviteLandingScreen` | UI screen | Deep link landing |

## Dependencies

| Allowed | Forbidden |
|---------|-----------|
| `auth`, `care_taxonomy`, `core/` entrypoints | Cross-feature `data/` |

## Side effects & freshness

Absence flows call server context APIs; refresh providers after commit.

## Permissions

Pet-scoped care context and absence APIs.

## Tests

`flutter_app/test/features/pet_care/`
