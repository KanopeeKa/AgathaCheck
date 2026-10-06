import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/notification_providers.dart';

/// One-time notice after legacy device-label bootstrap (Plan A, N13).
class NotificationDeviceSecurityIntro extends ConsumerWidget {
  const NotificationDeviceSecurityIntro({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider).valueOrNull;
    if (prefs?.showDeviceSecurityIntro != true) {
      return const SizedBox.shrink();
    }

    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                l.notificationDeviceSecurityIntro,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            IconButton(
              tooltip: l.close,
              onPressed: () => ref
                  .read(notificationPreferencesProvider.notifier)
                  .dismissDeviceSecurityIntro(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
