import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class RosterEmptyState extends StatelessWidget {
  const RosterEmptyState({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(l.peopleDeskEmptyBody, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('people_roster_empty_add'),
            onPressed: onAdd,
            child: Text(l.peopleAddPerson),
          ),
        ],
      ),
    );
  }
}

class RosterErrorState extends StatelessWidget {
  const RosterErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 8),
            Text(l.peopleListLoadError, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('people_roster_retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }
}
