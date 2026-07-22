import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_notification.dart';

/// Notifications grouped under a date label (Today, Yesterday, etc.).
class NotificationDateGroup {
  const NotificationDateGroup({
    required this.label,
    required this.notifications,
  });

  final String label;
  final List<AppNotification> notifications;
}

List<NotificationDateGroup> groupNotificationsByDate(
  BuildContext context,
  List<AppNotification> notifications,
) {
  final l = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  final groups = <String, List<AppNotification>>{};

  for (final n in notifications) {
    final date = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
    final String label;
    if (date == today) {
      label = l.today;
    } else if (date == yesterday) {
      label = 'Yesterday';
    } else {
      label = DateFormat.yMMMd().format(date);
    }
    groups.putIfAbsent(label, () => []).add(n);
  }

  return groups.entries
      .map((e) => NotificationDateGroup(label: e.key, notifications: e.value))
      .toList();
}
