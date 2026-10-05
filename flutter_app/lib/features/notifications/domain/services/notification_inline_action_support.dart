import '../entities/app_notification.dart';
import 'notification_inbox_v2_rules.dart';

enum NotificationInlineActionKind {
  shareInvite,
  householdInvite,
  accountNewSignIn,
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

  static bool supportsInlineActions(AppNotification notification) {
    if (!NotificationInboxV2Rules.needsResponse(notification)) return false;
    return kindFor(notification) != null;
  }

  static const _handlers = <String, NotificationInlineActionKind>{
    'shareInviteReceived': NotificationInlineActionKind.shareInvite,
    'householdInviteReceived': NotificationInlineActionKind.householdInvite,
    'accountNewSignIn': NotificationInlineActionKind.accountNewSignIn,
  };

  static NotificationInlineActionKind? kindFor(AppNotification notification) =>
      _handlers[notification.wireType];
}
