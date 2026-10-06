import 'package:flutter/material.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Title row and mark-all-read action for the notification slide-over panel.
class NotificationPanelHeader extends StatelessWidget {
  const NotificationPanelHeader({
    super.key,
    required this.l,
    required this.theme,
    required this.onMarkAllRead,
  });

  final AppLocalizations l;
  final ThemeData theme;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.notifications,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onMarkAllRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: Text(l.markAllRead),
            ),
          ),
        ],
      ),
    );
  }
}
