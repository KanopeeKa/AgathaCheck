import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notification_providers.dart';

/// For you suggestion row (FR-SC-1 core: headline + dismiss).
class NotificationSuggestionCard extends ConsumerWidget {
  const NotificationSuggestionCard({
    super.key,
    required this.notification,
    required this.onOpenPet,
  });

  final AppNotification notification;
  final VoidCallback onOpenPet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final unread = notification.isSuggestionUnread;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: unread ? FontWeight.bold : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (notification.showsHealthAdjacentDisclaimer) ...[
                        const SizedBox(height: 6),
                        Text(
                          l.notificationSuggestionVetDisclaimer,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    await ref
                        .read(notificationsProvider.notifier)
                        .submitSuggestionFeedback(notification.id, value);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'dismiss',
                      child: Text(l.careSuggestionDismiss),
                    ),
                    PopupMenuItem(
                      value: 'not_relevant',
                      child: Text(l.careSuggestionNotRelevant),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onOpenPet,
                child: Text(l.careSuggestionAccept),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatPetGroupHeader(String? petName) =>
    petName == null || petName.isEmpty ? 'Pet' : petName;
