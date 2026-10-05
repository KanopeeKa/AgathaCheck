---
title: Notifications feature
owner: Platform team
status: active
component_id: flutter.feature.notifications
last_updated: 2026-10-05
last_reviewed: 2026-10-05
---

# Purpose

In-app notification inbox, settings, and pending actions. **Non-goals:** push delivery implementation (server).

## Public entrypoint

`package:pet_profile_app/features/notifications/notifications.dart`

## Public surface

| Symbol | Kind | Reason |
|--------|------|--------|
| `AppNotification`, `NotificationKind`, `NotificationScope` | domain entities | Inbox models |
| `NotificationPreferences` | domain entity | Settings |
| `NotificationRepository` | domain port | Tests |
| `notificationScopeRules` | domain service | Filtering |
| `notificationProviders` | providers | Inbox and settings state |
| Notifications, settings, pending actions screens | UI screens | Router destinations |

## Dependencies

| Allowed | Forbidden |
|---------|-----------|
| `auth` public API, `core/` | Cross-feature `data/` |

## Side effects & freshness

Poll/refresh on screen open; badge via shell providers.

## Permissions

User-scoped notification APIs.

## Tests

`flutter_app/test/features/notifications/`
