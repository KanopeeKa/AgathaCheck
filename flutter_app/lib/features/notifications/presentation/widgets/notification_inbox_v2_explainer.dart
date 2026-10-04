import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/notification_providers.dart';

/// One-time v2 inbox explainer (FR-EM-3, AC-IN-9).
class NotificationInboxV2Explainer extends ConsumerWidget {
  const NotificationInboxV2Explainer({
    super.key,
    this.onOpenActions,
  });

  final void Function(BuildContext context)? onOpenActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider).valueOrNull;
    if (prefs?.v2ExplainerDismissedAt != null) {
      return const SizedBox.shrink();
    }

    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.secondaryContainer.withAlpha(120),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.notificationInboxV2Explainer,
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      if (onOpenActions != null) {
                        onOpenActions!(context);
                      }
                    },
                    child: Text(l.notificationInboxV2ExplainerActionsLink),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l.close,
              onPressed: () => ref
                  .read(notificationPreferencesProvider.notifier)
                  .dismissV2InboxExplainer(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
