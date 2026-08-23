---
title: Notifications journeys
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,notifications,journeys]
---

# Notifications journeys

User-facing flows for the global bell and in-app notification feed (D7–D11 in [notification-decisions.md](../features/notification-decisions.md)).

## Open notification panel from header bell

On every authenticated screen, the header shows a persistent bell. Tapping opens a full-height right slide-over panel (not a separate `/g/notifications` route).

## Filter by kind (Care / Organisation)

Filter chips **All / Care / Organisation** sit above the date-grouped list. Badge on the bell is a single combined unread count across kinds (D8).

## Care-kind reminders

Care notifications surface health, weight, and other entry due/overdue items. Read/unread only — no derived “resolved” state (D9).

## Administrative-kind actionable items

Administrative notifications include pending shares, foster placements, adoption placements, custody transfers, org messages, and agreement-withdrawal alerts. **Resolved** is derived when the referenced object transitions (accepted/declined/completed), not manual dismiss (D9–D10).

## Urgent administrative items

Agreement withdrawal and similar paths use `priority=urgent` styling (pinned, warning accent) but remain Administrative kind (D11).

## Notification settings

Per-user notification preferences live under Account → notification settings (`notification_settings_screen.dart`). Org-scoped self-management prefs are reached from org people cards (D26–D27).

---

BDD: `notifications.feature` · E2E: navigation contract requires bell + panel ready state
