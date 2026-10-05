import 'package:flutter/material.dart';

import '../entities/app_notification.dart';

/// Cross-feature inline Accept / Decline (share / household invites).
///
/// Implemented in the experience composition layer; notifications UI reads
/// [notificationInlineActionsProvider] only.
abstract class NotificationInlineActions {
  Future<void> accept(BuildContext context, AppNotification notification);

  Future<void> declineWithUndoSnackBar(
    BuildContext context,
    AppNotification notification,
  );
}

/// Invite no longer pending (inline action should show already-handled UX).
class StaleNotificationException implements Exception {}
