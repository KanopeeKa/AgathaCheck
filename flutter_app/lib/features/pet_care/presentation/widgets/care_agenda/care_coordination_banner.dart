import 'package:flutter/material.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../care_surface/care_surface_tokens.dart';

/// Links guardians to each pet's care on a shared due day (AC-CO-02).
class CareCoordinationBanner extends StatelessWidget {
  const CareCoordinationBanner({
    super.key,
    required this.date,
    required this.dateKey,
    required this.petNames,
    required this.onOpenPet,
  });

  final DateTime date;
  final String dateKey;
  final Map<String, String> petNames;
  final void Function(String petId) onOpenPet;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateLabel = formatCalendarDateDisplay(date);
    final petIds = petNames.keys.toList()..sort();

    return Semantics(
      container: true,
      identifier: 'care_coordination_banner_$dateKey',
      child: Padding(
        padding: CareSurfaceTokens.collectionInsetRowPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.careAgendaCoordinationMessage(dateLabel),
              key: Key('care_coordination_message_$dateKey'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final petId in petIds)
                  Semantics(
                    button: true,
                    identifier: 'care_coordination_pet_link_$petId',
                    label: l.careAgendaCoordinationPetLink(petNames[petId]!),
                    child: TextButton(
                      key: Key('care_coordination_pet_$petId'),
                      onPressed: () => onOpenPet(petId),
                      child: Text(l.careAgendaCoordinationPetLink(petNames[petId]!)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
