import 'package:flutter/material.dart';

import '../../../../../core/widgets/async_state/async_state.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/pet_profile.dart';

/// How the guardian pet list resolved for the away-plan pets step.
enum AwayPlanPetsLoadPhase { loading, error, ready }

class PlannedAbsencePetsStep extends StatelessWidget {
  const PlannedAbsencePetsStep({
    super.key,
    required this.loadPhase,
    required this.pets,
    required this.selectedPetIds,
    required this.onSelectionChanged,
    this.validationMessage,
    this.onRetryPetsLoad,
    this.accountHasPets = false,
  });

  final AwayPlanPetsLoadPhase loadPhase;
  final List<Pet> pets;
  final Set<String> selectedPetIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final String? validationMessage;
  final VoidCallback? onRetryPetsLoad;
  final bool accountHasPets;

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
        if (loadPhase == AwayPlanPetsLoadPhase.loading)
          LabelledProgress(label: l.awayPetsLoading, centered: false)
        else if (loadPhase == AwayPlanPetsLoadPhase.error)
          AsyncErrorState(
            title: l.loadErrorYourPets,
            onRetry: onRetryPetsLoad,
            retryKey: const Key('planned_absence_pets_load_retry'),
          )
        else if (selectablePets.isEmpty)
          Text(
            accountHasPets ? l.awayNoEligiblePets : l.noPetsYet,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...selectablePets.map((pet) {
            final selected = selectedPetIds.contains(pet.id);
            void toggleSelected() {
              final next = Set<String>.from(selectedPetIds);
              if (selected) {
                next.remove(pet.id);
              } else {
                next.add(pet.id);
              }
              onSelectionChanged(next);
            }

            return Semantics(
              identifier: 'planned_absence_pet_${pet.id}',
              label: '${pet.name} ${pet.species}',
              checked: selected,
              button: true,
              excludeSemantics: true,
              onTap: toggleSelected,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: toggleSelected,
                  child: CheckboxListTile(
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
                  ),
                ),
              ),
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
