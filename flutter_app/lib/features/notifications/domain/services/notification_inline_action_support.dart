import '../entities/app_notification.dart';
import 'notification_inbox_v2_rules.dart';

enum NotificationInlineActionKind {
  shareInvite,
  householdInvite,
  accountNewSignIn,
  accountPasswordChanged,
}

class InlineActionLabels {
  const InlineActionLabels({required this.decline, required this.accept});

  final String decline;
  final String accept;
}

/// Wire types that support Accept / Decline inline controls (PR4 core).
///
/// Foster/adoption/custody pending actions stay row-navigation only until a
/// notifications API bridge exists (frozen organization boundary).
class NotificationInlineActionSupport {
  const NotificationInlineActionSupport._();

  static bool _passwordChangedInlineWindow(AppNotification notification) {
    if (notification.wireType != 'accountPasswordChanged') return false;
    if (notification.resolvedAt != null) return false;
    final age = DateTime.now().difference(notification.createdAt);
    return !age.isNegative && age <= const Duration(days: 7);
  }

  static bool supportsInlineActions(AppNotification notification) {
    if (_passwordChangedInlineWindow(notification)) return true;
    if (!NotificationInboxV2Rules.needsResponse(notification)) return false;
    return kindFor(notification) != null;
  }

  static const _handlers = <String, NotificationInlineActionKind>{
    'shareInviteReceived': NotificationInlineActionKind.shareInvite,
    'householdInviteReceived': NotificationInlineActionKind.householdInvite,
    'accountNewSignIn': NotificationInlineActionKind.accountNewSignIn,
    'accountPasswordChanged':
        NotificationInlineActionKind.accountPasswordChanged,
  };

  static NotificationInlineActionKind? kindFor(AppNotification notification) =>
      _handlers[notification.wireType];
}
