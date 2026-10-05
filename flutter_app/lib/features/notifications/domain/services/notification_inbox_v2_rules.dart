import '../entities/app_notification.dart';
import '../entities/notification_kind.dart';

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

  static const accountPasswordChangedInlineDays = 7;

  static bool _accountPasswordChangedNeedsResponse(AppNotification n) {
    if (n.wireType != 'accountPasswordChanged') return false;
    final age = DateTime.now().difference(n.createdAt);
    return !age.isNegative &&
        age <= const Duration(days: accountPasswordChangedInlineDays);
  }

  static bool needsResponse(AppNotification n) {
    if (n.isRead) return false;
    if (n.kind == NotificationKind.administrative && n.resolvedAt == null) {
      return true;
    }
    if (n.kind == NotificationKind.relationship && n.resolvedAt == null) {
      return _relationshipNeedsResponseWireType(n.wireType);
    }
    if (n.kind == NotificationKind.account && n.resolvedAt == null) {
      if (n.wireType == 'accountNewSignIn') return true;
      return _accountPasswordChangedNeedsResponse(n);
    }
    return false;
  }

  static bool _relationshipNeedsResponseWireType(String wireType) {
    const actionable = {
      'shareInviteReceived',
      'householdInviteReceived',
      'absenceGuestGranted',
    };
    return actionable.contains(wireType);
  }

  static bool isUrgent(AppNotification n) =>
      n.priority == NotificationPriority.urgent;

  /// Bell numeric badge (FR-BG-1, matrix §5.4.1).
  static int bellNumericCount(Iterable<AppNotification> notifications) {
    return notifications
        .where((n) => isActivityKind(n.kind))
        .where((n) => !n.isRead)
        .where((n) => needsResponse(n) || isUrgent(n))
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
