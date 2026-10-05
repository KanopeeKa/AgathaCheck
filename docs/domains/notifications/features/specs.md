---
title: Notifications specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-04
tags: [domain,notifications,specs]
domain: notifications
---

# Notifications specs

> **Target model: [Notifications v2](notifications-v2-spec.md)** (accepted 2026-10-04). The axes below show v2. Rows marked *today* describe the code until the named PR lands.

## Axes (orthogonal)

| Field | Values | Notes |
|-------|--------|-------|
| `kind` | `relationship` \| `administrative` \| `suggestion` \| `account` | Set at creation from the type→kind map (v2 §3.4). Drives the **Activity** (relationship, administrative, account) and **For you** (suggestion) tabs. *Today:* `care \| administrative` with chips, until PR1/PR2 |
| `scope` | `pet_care` \| `organization` (`guardian` accepted as a legacy alias on the wire) | Grouping label (“From: org name”), not separate routes |
| `priority` | `normal` \| `urgent` | Urgent for agreement withdrawal and subscription payment issues (D11, A9) |
| `resolvedAt` | nullable timestamp | Items referencing an open object: administrative, relationship invites, account A1/A9 (D9 as extended by v2) |

Wire enums: `flutter_app/lib/features/notifications/domain/entities/notification_kind.dart`

## Flutter modules

- Panel UI: `presentation/widgets/notification_panel.dart`
- Navigation targets: `presentation/utils/notification_navigation.dart`
- Scope rules: `domain/services/notification_scope_rules.dart`

## Backend

Notification rows served via `notification_remote_datasource`; preferences entity `notification_preferences` (see fostering G0 §11 for DPIA alignment D31).

## Tests

- BDD: `flutter_app/test/bdd/features/notifications.feature`; v2 scenarios go in `notifications_v2.feature`, and care-in-inbox scenarios are tagged `@legacy` in PR1 (v2 §12)
- Extend v2 scenarios in `notifications_v2.feature` as each PR lands (tabs, resolved semantics — program-contract §6.1 footnote)
- UAT live E2E: call `refreshByRemount()` after API seed when due events are missing on home — see [.agents/memory/uat-live-e2e-triage.md](/.agents/memory/uat-live-e2e-triage.md).

Kind vs scope semantics: [notification-decisions.md](notification-decisions.md) §B.

---

Contract detail: [/docs/domains/cross-domain/changes/program-contract.md](/docs/domains/cross-domain/changes/program-contract.md) §3

## Planned: People & Care Team

These changes are agreed but not implemented. See the [People & Care Team spec](/docs/domains/people/features/people-care-team.md).

- **D21:** when someone is named as looking after an occurrence, only they get its reminder.
- **D25:** when nobody is named, the record owner and Full access members get the reminder. Can log care members don't, unless they opt in.
- **Setting:** pet parents can opt in to notifications for all events on their pets. This is a new key in `notification_preferences`.
- **Household notices:** a pet being removed from a household sends a neutral notice (D22). Absence access granted by someone else notifies the record owner (D19).

Today, `petNotificationRecipientIds` in `server/lib/petAccess.js` sends to every sharer.
