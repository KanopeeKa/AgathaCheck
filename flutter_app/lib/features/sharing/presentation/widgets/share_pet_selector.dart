import 'package:flutter/material.dart';

import '../../../pet_profile/domain/entities/pet.dart';
import '../../../../l10n/app_localizations.dart';

/// Horizontal pet chips when sharing multiple pets.
class SharePetSelector extends StatelessWidget {
  const SharePetSelector({
    required this.pets,
    required this.selectedPetId,
    required this.onSelected,
  });

  final List<Pet> pets;
  final String? selectedPetId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (pets.length <= 1) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.sharePetSelectPet, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pets.map((pet) {
            final selected = pet.id == selectedPetId;
            return FilterChip(
              key: Key('share_pet_chip_${pet.id}'),
              label: Text(pet.name),
              selected: selected,
              onSelected: (_) => onSelected(pet.id),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
