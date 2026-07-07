import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';

class HealthEntryPetSelector extends StatelessWidget {
  const HealthEntryPetSelector({
    required this.pets,
    required this.selectedPetIds,
    required this.isEdit,
    required this.onChanged,
  });

  final List<Pet> pets;
  final Set<String> selectedPetIds;
  final bool isEdit;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    if (isEdit) {
      final pet = pets.where((p) => selectedPetIds.contains(p.id)).firstOrNull;
      return InputDecorator(
        decoration: InputDecoration(labelText: l.petLabel),
        child: Text(pet?.name ?? l.unknownPet),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.selectPets,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (selectedPetIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l.atLeastOnePetMustBeSelected,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        if (pets.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              l.selectMultiplePetsHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pets.map((pet) {
            final isSelected = selectedPetIds.contains(pet.id);
            return FilterChip(
              avatar: isSelected
                  ? null
                  : CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      child: Text(
                        pet.name.isNotEmpty ? pet.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
              label: Text(pet.name),
              selected: isSelected,
              onSelected: (selected) {
                final newSet = Set<String>.from(selectedPetIds);
                if (selected) {
                  newSet.add(pet.id);
                } else {
                  newSet.remove(pet.id);
                }
                onChanged(newSet);
              },
            );
          }).toList(),
        ),
        if (pets.length > 1) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => onChanged(pets.map((p) => p.id).toSet()),
                icon: const Icon(Icons.select_all, size: 18),
                label: Text(l.selectAll),
              ),
              TextButton.icon(
                onPressed: () => onChanged({}),
                icon: const Icon(Icons.deselect, size: 18),
                label: Text(l.clearSelection),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
