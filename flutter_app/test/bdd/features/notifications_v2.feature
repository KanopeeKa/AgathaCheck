# Notifications v2 — PR1 bootstrap
#
# PR1 acceptance is covered by:
# - server/test/checkDueNotifications.inbox.test.js (no overdue/due_soon inbox inserts)
# - server/test/notificationsV2Migration.test.js (092 migration)
# - flutter_app/test/features/notifications/domain/notification_kind_test.dart
#
# Inbox UI and indicator BDD scenarios land in PR2+.

@notifications-v2
Feature: Notifications v2 inbox programme
