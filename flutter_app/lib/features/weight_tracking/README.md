---
title: Weight tracking feature
owner: Pet Care team
status: active
component_id: flutter.feature.weight_tracking
last_updated: 2026-10-05
last_reviewed: 2026-10-05
---

# Purpose

Weight entries, hub screen, and record-weight sheet. **Non-goals:** care intelligence weight suggestions (consumer only).

## Public entrypoint

`package:pet_profile_app/features/weight_tracking/weight_tracking.dart`

## Public surface

| Symbol | Kind | Reason |
|--------|------|--------|
| `WeightEntry`, `WeightFulfils` | domain entities | Charts and forms |
| `weightProviders` | providers | Weight series state |
| `WeightHubScreen`, `RecordWeightSheet` | UI | Router and sheets |

## Dependencies

| Allowed | Forbidden |
|---------|-----------|
| `auth`, `core/` | Cross-feature `data/` |

## Side effects & freshness

Remote weight entries; refresh after record.

## Permissions

Pet-scoped weight APIs.

## Tests

`flutter_app/test/features/weight_tracking/`
