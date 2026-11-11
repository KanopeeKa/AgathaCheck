import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/services/notification_inbox_v2_rules.dart';
import '../providers/notification_providers.dart';

/// Marks the current inbox tab as read and shows a truthful success or failure snackbar.
Future<void> performMarkAllRead(
  BuildContext context,
  WidgetRef ref, {
  required NotificationInboxTab scope,
}) async {
  try {
    await ref.read(notificationsProvider.notifier).markAllAsRead(scope: scope);
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.notificationsMarkedRead)));
  } catch (_) {
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.notificationsMarkReadFailed)));
  }
}
