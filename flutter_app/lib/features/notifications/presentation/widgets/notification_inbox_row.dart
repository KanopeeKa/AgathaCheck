import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_scope.dart';
import '../../domain/services/notification_inline_action_support.dart';
import '../../domain/services/notification_inline_actions.dart';
import '../../domain/services/notification_inbox_v2_rules.dart';
import '../providers/notification_inline_actions_provider.dart';
import '../providers/notification_providers.dart';
import '../utils/notification_navigation.dart';
import 'notification_inline_actions_bar.dart';
import 'notification_tile.dart';

typedef NotificationInboxTileTap =
    Future<void> Function(
      BuildContext context,
      WidgetRef ref,
      AppNotification notification,
    );

/// Inbox row with optional inline Accept / Decline (PR4).
class NotificationInboxRow extends ConsumerStatefulWidget {
  const NotificationInboxRow({
    super.key,
    required this.notification,
    required this.listScope,
    this.onNotificationTap,
  });

  final AppNotification notification;
  final NotificationScope listScope;
  final NotificationInboxTileTap? onNotificationTap;

  @override
  ConsumerState<NotificationInboxRow> createState() =>
      _NotificationInboxRowState();
}

class _NotificationInboxRowState extends ConsumerState<NotificationInboxRow> {
  bool _busy = false;
  String? _errorMessage;

  bool get _showInline => NotificationInlineActionSupport.supportsInlineActions(
    widget.notification,
  );

  Future<void> _onTap() async {
    if (widget.onNotificationTap != null) {
      await widget.onNotificationTap!(context, ref, widget.notification);
      return;
    }
    if (!widget.notification.isRead) {
      await ref
          .read(notificationsProvider.notifier)
          .markAsRead(widget.notification.id);
    }
    if (!mounted) return;
    navigateFromNotification(context, widget.notification);
  }

  Future<void> _runInline(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      await action();
      if (mounted) {
        setState(() {
          _busy = false;
          _errorMessage = null;
        });
      }
    } on StaleNotificationException {
      await ref.read(notificationsProvider.notifier).refresh();
      if (mounted) {
        setState(() {
          _busy = false;
          _errorMessage = AppLocalizations.of(
            context,
          )!.notificationAlreadyHandled;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _errorMessage = AppLocalizations.of(
            context,
          )!.notificationInlineActionFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final runner = ref.read(notificationInlineActionsProvider);
    final needsResponse = NotificationInboxV2Rules.needsResponse(
      widget.notification,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NotificationTile(
          notification: widget.notification,
          listScope: widget.listScope,
          showActionNeeded: needsResponse && !_showInline,
          onTap: _onTap,
        ),
        if (_showInline)
          NotificationInlineActionsBar(
            busy: _busy,
            errorMessage: _errorMessage,
            onAccept: () =>
                _runInline(() => runner.accept(context, widget.notification)),
            onDecline: () => _runInline(
              () =>
                  runner.declineWithUndoSnackBar(context, widget.notification),
            ),
            onRetry: () => setState(() => _errorMessage = null),
          ),
      ],
    );
  }
}
