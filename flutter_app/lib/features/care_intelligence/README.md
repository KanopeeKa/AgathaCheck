---
title: Care intelligence feature
owner: Pet Care team
status: active
component_id: flutter.feature.care_intelligence
last_updated: 2026-10-06
last_reviewed: 2026-10-06
---

# Purpose

Server-driven care suggestions and safeguards on pet profile surfaces. **Non-goals:** schedule authoring (Care Item / health entries).

## Public entrypoint

`package:pet_profile_app/features/care_intelligence/care_intelligence.dart`

## Public surface

| Symbol | Kind | Reason |
|--------|------|--------|
| `CareRecommendation`, `CareSafeguard` | domain entities | UI models |
| `CareIntelligenceRepository` | domain port | Tests and overrides |
| `WeightProvenance` | domain value | Weight suggestion context |
| `careRecommendationsProvider` | provider | Load suggestions for a pet |

## Dependencies

| Allowed | Forbidden |
|---------|-----------|
| `core/`, `auth` public API | Other features' `data/` |

## Side effects & freshness

Fetches recommendations on demand; invalidate via provider refresh after pet context changes.

## Permissions

Authenticated pet-scoped API calls.

## Tests

`flutter_app/test/features/care_intelligence/`
