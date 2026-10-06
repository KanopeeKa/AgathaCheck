import 'package:flutter/material.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Error state when the notification inbox fails to load.
class NotificationPanelErrorView extends StatelessWidget {
  const NotificationPanelErrorView({
    super.key,
    required this.error,
    required this.l,
    required this.theme,
    required this.onRetry,
  });

  final Object error;
  final AppLocalizations l;
  final ThemeData theme;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            l.failedToLoadNotifications(error.toString()),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: onRetry, child: Text(l.retry)),
        ],
      ),
    );
  }
}
