import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/planned_absence.dart';
import '../../domain/entities/planned_absence_pet_carer.dart';
import '../away_plan_copy.dart';

class AwayPlanCarersSection extends StatelessWidget {
  const AwayPlanCarersSection({
    super.key,
    required this.absence,
    required this.petNamesById,
  });

  final PlannedAbsence absence;
  final Map<String, String> petNamesById;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final carersByPetId = {
      for (final carer in absence.petCarers) carer.petId: carer,
    };
    final orderedPetIds = [...absence.petIds]..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.careContextAwayPlanWhoIsCaringTitle,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final petId in orderedPetIds) ...[
                  _CarerRow(
                    petName: petNamesById[petId] ?? '',
                    carerLabel: AwayPlanCopy.petCarerLabel(
                      l,
                      carersByPetId[petId] ??
                          PlannedAbsencePetCarer(petId: petId),
                    ),
                  ),
                  if (petId != orderedPetIds.last) const Divider(height: 24),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CarerRow extends StatelessWidget {
  const _CarerRow({required this.petName, required this.carerLabel});

  final String petName;
  final String carerLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(petName, style: theme.textTheme.titleSmall)),
        Expanded(
          child: Text(
            carerLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
