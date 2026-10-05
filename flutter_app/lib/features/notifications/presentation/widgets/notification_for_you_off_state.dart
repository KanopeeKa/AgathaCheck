import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/notification_providers.dart';
import '../../domain/entities/notification_preferences.dart';

/// FR-SE-2 / AC-SE-2: For you tab when Agatha Suggestions in-app is off.
class NotificationForYouOffState extends ConsumerWidget {
  const NotificationForYouOffState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              l.notificationInboxForYouSuggestionsOff,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l.notificationSettingsAgathaComputationHelp,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(l.notificationSettingsCategorySuggestions),
              value: false,
              onChanged: (v) async {
                if (!v) return;
                final prefs =
                    ref.read(notificationPreferencesProvider).valueOrNull ??
                    NotificationPreferences();
                await ref
                    .read(notificationPreferencesProvider.notifier)
                    .updatePreferences(
                      prefs.copyWith(agathaSuggestionsInApp: true),
                    );
              },
            ),
            TextButton(
              onPressed: () => context.push('/notifications/settings'),
              child: Text(l.notificationSettings),
            ),
          ],
        ),
      ),
    );
  }
}
