import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';

/// Legacy deep-link target for frozen foster/adoption/custody notifications.
class PendingActionsScreen extends StatelessWidget {
  const PendingActionsScreen({super.key, this.focus});

  final String? focus;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.notificationActionNeeded)),
      body: ListView(
        key: const Key('pending_actions_screen'),
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l.pendingActionsUnavailableTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l.pendingActionsUnavailableBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('pending_actions_open_inbox'),
            onPressed: () => context.go('/notifications'),
            child: Text(l.pendingActionsOpenInbox),
          ),
        ],
      ),
    );
  }
}
