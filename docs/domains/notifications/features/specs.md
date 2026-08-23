---
title: Notifications specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,notifications,specs]
---

# Notifications specs

## Axes (orthogonal)

| Field | Values | Notes |
|-------|--------|-------|
| `kind` | `care` \| `administrative` | Set at creation — drives filter chips (D7) |
| `scope` | `guardian` \| `organization` | Grouping label (“From: org name”), not separate routes |
| `priority` | `normal` \| `urgent` | Urgent for agreement withdrawal etc. (D11) |
| `resolvedAt` | nullable timestamp | Administrative items with referenced objects only (D9) |

Wire enums: `flutter_app/lib/features/notifications/domain/entities/notification_kind.dart`

## Flutter modules

- Panel UI: `presentation/widgets/notification_panel.dart`
- Navigation targets: `presentation/utils/notification_navigation.dart`
- Scope rules: `domain/services/notification_scope_rules.dart`

## Backend

Notification rows served via `notification_remote_datasource`; preferences entity `notification_preferences` (see fostering G0 §11 for DPIA alignment D31).

## Tests

- BDD: `flutter_app/test/bdd/features/notifications.feature`
- Extend scenarios when panel filter chips and administrative resolved semantics ship (program-contract §6.1)
- UAT live E2E: call `refreshByRemount()` after API seed when due events are missing on home — see [.agents/memory/uat-live-e2e-triage.md](/.agents/memory/uat-live-e2e-triage.md).

Kind vs scope semantics: [notification-decisions.md](notification-decisions.md) §B.

---

Contract detail: [/docs/domains/cross-domain/changes/program-contract.md](/docs/domains/cross-domain/changes/program-contract.md) §3
