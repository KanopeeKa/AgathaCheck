---
title: Care taxonomy feature
owner: Pet Care team
status: active
component_id: flutter.feature.care_taxonomy
last_updated: 2026-10-05
last_reviewed: 2026-10-05
---

# Purpose

Shared care family definitions, planning mode, and taxonomy constants for filters and forms. **Non-goals:** occurrence engine or agenda UI.

## Public entrypoint

`package:pet_profile_app/features/care_taxonomy/care_taxonomy.dart`

## Public surface

| Symbol | Kind | Reason |
|--------|------|--------|
| `CareFamilyDefinition` | domain type | Event filters and pickers |
| `CarePlanningMode`, `CareSetting`, `CareImportance` | domain enums | Forms and labels |
| `careTaxonomy` | domain registry | Lookup helpers |

## Dependencies

| Allowed | Forbidden |
|---------|-----------|
| `core/` only | Feature `data/` and private widgets |

## Side effects & freshness

Pure domain; no I/O.

## Permissions

None.

## Tests

`flutter_app/test/features/care_taxonomy/` (mirror as added)
