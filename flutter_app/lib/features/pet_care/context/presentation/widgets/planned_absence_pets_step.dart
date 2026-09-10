import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';

class PlannedAbsencePetsStep extends StatelessWidget {
  const PlannedAbsencePetsStep({
    super.key,
    required this.pets,
    required this.selectedPetIds,
    required this.onSelectionChanged,
    this.validationMessage,
  });

  final List<Pet> pets;
  final Set<String> selectedPetIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final String? validationMessage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final selectablePets = pets.where((pet) => !pet.passedAway).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.careContextAwayPetsStepTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          l.careContextAwayPetsStepBody,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (selectablePets.isEmpty)
          Text(
            l.noPetsYet,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...selectablePets.map((pet) {
            final selected = selectedPetIds.contains(pet.id);
            return CheckboxListTile(
              key: Key('planned_absence_pet_${pet.id}'),
              value: selected,
              onChanged: (checked) {
                final next = Set<String>.from(selectedPetIds);
                if (checked == true) {
                  next.add(pet.id);
                } else {
                  next.remove(pet.id);
                }
                onSelectionChanged(next);
              },
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(pet.name),
              subtitle: Text(pet.species),
            );
          }),
        if (validationMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            validationMessage!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
