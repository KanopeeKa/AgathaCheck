import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class PeopleHubPlaceholder extends StatelessWidget {
  const PeopleHubPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      key: const Key('people_hub_detail_placeholder'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          l.peopleHubSelectSomeone,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
