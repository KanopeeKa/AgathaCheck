import '../entities/app_notification.dart';
import 'notification_inbox_v2_rules.dart';

enum NotificationInlineActionKind {
  shareInvite,
  householdInvite,
  fosterPlacement,
  adoptionPlacement,
  custodyTransfer,
}

/// Wire types that support Accept / Decline inline controls (PR4 core).
class NotificationInlineActionSupport {
  const NotificationInlineActionSupport._();

  static bool supportsInlineActions(AppNotification notification) {
    if (!NotificationInboxV2Rules.needsResponse(notification)) return false;
    return kindFor(notification) != null;
  }

  static const _handlers = <String, NotificationInlineActionKind>{
    'shareInviteReceived': NotificationInlineActionKind.shareInvite,
    'householdInviteReceived': NotificationInlineActionKind.householdInvite,
    'pendingFosterPlacementReceived':
        NotificationInlineActionKind.fosterPlacement,
    'pendingAdoptionPlacementReceived':
        NotificationInlineActionKind.adoptionPlacement,
    'pendingCustodyTransferReceived':
        NotificationInlineActionKind.custodyTransfer,
  };

  static NotificationInlineActionKind? kindFor(AppNotification notification) =>
      _handlers[notification.wireType];
}
