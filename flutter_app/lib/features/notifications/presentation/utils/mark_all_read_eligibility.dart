import '../../domain/entities/app_notification.dart';
import '../../domain/services/notification_inbox_v2_rules.dart';

/// Shared rule for bulk mark-read in the panel and full inbox (D-4.4).
class MarkAllReadEligibility {
  const MarkAllReadEligibility._();

  static bool tabHasUnread(
    Iterable<AppNotification> notifications,
    NotificationInboxTab tab,
  ) {
    return notifications.any((n) {
      if (!NotificationInboxV2Rules.belongsToTab(n, tab)) return false;
      if (tab == NotificationInboxTab.forYou) {
        return n.isSuggestionUnread;
      }
      return !n.isRead;
    });
  }

  static bool isEligible({
    required bool isLoading,
    required Iterable<AppNotification> notifications,
    required NotificationInboxTab tab,
  }) {
    if (isLoading) return false;
    return tabHasUnread(notifications, tab);
  }
}
