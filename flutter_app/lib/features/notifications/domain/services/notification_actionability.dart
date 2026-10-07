import '../entities/notification_kind.dart';

/// Wire types needing a response when [resolvedAt] is null (spec §5.4, D10).
/// Keep in sync with `server/lib/notifications/notificationActionability.js`.
class NotificationActionability {
  const NotificationActionability._();

  static const Set<String> needsResponseWireTypes = {
    'shareInviteReceived',
    'householdInviteReceived',
    'pendingFosterPlacementReceived',
    'pendingAdoptionPlacementReceived',
    'pendingCustodyTransferReceived',
    'connectionRequestReceived',
    'accountNewSignIn',
  };

  static bool needsResponse({
    required NotificationKind kind,
    required String wireType,
    DateTime? resolvedAt,
  }) {
    if (resolvedAt != null) return false;
    if (!needsResponseWireTypes.contains(wireType)) return false;
    switch (kind) {
      case NotificationKind.relationship:
      case NotificationKind.administrative:
      case NotificationKind.account:
        return true;
      case NotificationKind.suggestion:
      case NotificationKind.care:
        return false;
    }
  }
}
