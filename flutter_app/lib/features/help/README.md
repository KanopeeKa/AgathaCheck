---
title: Help feature
owner: Pet Care team
status: active
component_id: flutter.feature.help
last_updated: 2026-10-06
last_reviewed: 2026-10-06
---

# Purpose

In-app help and FAQ entry screen. **Non-goals:** legal documents (`about`), notifications, or support ticketing.

## Public entrypoint

`package:pet_profile_app/features/help/help.dart`

## Public surface

| Symbol | Kind | Reason |
|--------|------|--------|
| `HelpScreen` | UI screen | Router destination |

## Dependencies

| Allowed | Forbidden |
|---------|-----------|
| `core/`, `l10n/` | Other feature internals |

## Side effects & freshness

Static/help content; optional future remote FAQ.

## Permissions

None.

## Tests

`flutter_app/test/features/help/` (as present)
