import 'package:flutter/material.dart';

import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../pet_profile/screens/widgets/pet_care_global_events_filters.dart';

/// Multi-select pet chips for global All care — synced to `?pet=` on the route.
class GlobalEventsPetChipBar extends StatelessWidget {
  const GlobalEventsPetChipBar({
    super.key,
    required this.shellPets,
    required this.filters,
    required this.onChanged,
  });

  final List<Pet> shellPets;
  final PetCareGlobalEventsFilters filters;
  final ValueChanged<PetCareGlobalEventsFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    if (shellPets.length <= 1) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final sortedPets = [...shellPets]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Padding(
      key: const Key('global_events_pet_chip_bar'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              key: const Key('global_events_pet_all'),
              label: Text(l.allPets),
              selected: filters.isPetSelected(null),
              onSelected: (_) => onChanged(filters.copyWith(petIds: {})),
            ),
            for (final pet in sortedPets) ...[
              const SizedBox(width: 8),
              FilterChip(
                key: Key('global_events_pet_${pet.id}'),
                label: Text(pet.name),
                selected: filters.isPetSelected(pet.id),
                onSelected: (_) => onChanged(filters.togglePetId(pet.id)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
