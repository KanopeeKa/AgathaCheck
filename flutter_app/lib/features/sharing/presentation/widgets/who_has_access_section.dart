import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/household_pet_access.dart';

class WhoHasAccessSection extends StatelessWidget {
  const WhoHasAccessSection({super.key, required this.householdAccess});

  final List<HouseholdPetAccess> householdAccess;

  @override
  Widget build(BuildContext context) {
    if (householdAccess.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.whoHasAccessHouseholdTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ...householdAccess.map(
          (row) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(row.displayName),
              subtitle: Text(
                '${row.householdName} · ${row.tierLabel}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
