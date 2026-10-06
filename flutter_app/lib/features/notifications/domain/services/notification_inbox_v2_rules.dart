import '../entities/app_notification.dart';
import '../entities/notification_kind.dart';
import 'notification_actionability.dart';

enum NotificationInboxTab { activity, forYou }

/// Notifications v2 inbox classification (spec §5, §5.4.1).
class NotificationInboxV2Rules {
  const NotificationInboxV2Rules._();

  static bool isActivityKind(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.relationship:
      case NotificationKind.administrative:
      case NotificationKind.account:
        return true;
      case NotificationKind.suggestion:
        return false;
      case NotificationKind.care:
        return false;
    }
  }

  static bool isForYouKind(NotificationKind kind) =>
      kind == NotificationKind.suggestion;

  static bool belongsToTab(AppNotification n, NotificationInboxTab tab) {
    switch (tab) {
      case NotificationInboxTab.activity:
        return isActivityKind(n.kind);
      case NotificationInboxTab.forYou:
        return isForYouKind(n.kind);
    }
  }

  static bool needsResponse(AppNotification n) {
    return NotificationActionability.needsResponse(
      kind: n.kind,
      wireType: n.wireType,
      resolvedAt: n.resolvedAt,
    );
  }

  static bool isUrgent(AppNotification n) =>
      n.priority == NotificationPriority.urgent;

  /// Bell numeric badge (FR-BG-1, matrix §5.4.1).
  static int bellNumericCount(Iterable<AppNotification> notifications) {
    return notifications
        .where((n) => isActivityKind(n.kind))
        .where((n) => needsResponse(n) || (isUrgent(n) && !n.isRead))
        .length;
  }

  static bool bellShowDot(Iterable<AppNotification> notifications) {
    if (bellNumericCount(notifications) > 0) return false;
    final hasOtherUnreadActivity = notifications.any(
      (n) => isActivityKind(n.kind) && !n.isRead,
    );
    final hasUnreadSuggestions = notifications.any(
      (n) => isForYouKind(n.kind) && n.isSuggestionUnread,
    );
    return hasOtherUnreadActivity || hasUnreadSuggestions;
  }

  static int activityTabIndicatorCount(
    Iterable<AppNotification> notifications,
  ) => bellNumericCount(notifications);

  static bool forYouTabShowDot(Iterable<AppNotification> notifications) =>
      notifications.any((n) => isForYouKind(n.kind) && (n.isSuggestionUnread));
}
