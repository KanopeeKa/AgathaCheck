import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/services/notification_inline_actions.dart';

final notificationInlineActionsProvider = Provider<NotificationInlineActions>(
  (ref) => const _UnconfiguredNotificationInlineActions(),
);

class _UnconfiguredNotificationInlineActions
    implements NotificationInlineActions {
  const _UnconfiguredNotificationInlineActions();

  @override
  Future<void> accept(
    BuildContext context,
    AppNotification notification,
  ) async {}

  @override
  Future<void> declineWithUndoSnackBar(
    BuildContext context,
    AppNotification notification,
  ) async {}

  @override
  Future<void> confirmAccountSignInWasMe(
    BuildContext context,
    AppNotification notification,
  ) async {}

  @override
  Future<void> startSecureAccountFlow(
    BuildContext context,
    AppNotification notification,
  ) async {}
}
