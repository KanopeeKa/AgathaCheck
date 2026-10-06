import 'package:flutter/material.dart';
import 'package:pet_profile_app/core/utils/constants.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

/// Species, breed, gender, age, and weight chips on the pet detail card.
class PetDetailProfileInfoChips extends StatelessWidget {
  const PetDetailProfileInfoChips({
    super.key,
    required this.pet,
    required this.weightChipLabel,
  });

  final Pet pet;
  final String? weightChipLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Semantics(
          identifier: 'pet_detail_species_chip',
          label: pet.species,
          child: PetInfoChipWidget(
            iconWidget: AppConstants.speciesIconWidget(pet.species, size: 18),
            label: pet.species,
          ),
        ),
        if (pet.breed.isNotEmpty)
          PetInfoChip(icon: Icons.pets, label: pet.breed),
        if (pet.gender != null && pet.gender!.isNotEmpty)
          PetInfoChip(
            icon: pet.gender == 'Male' ? Icons.male : Icons.female,
            label: pet.gender!,
          ),
        if (pet.ageDisplay != null)
          Semantics(
            identifier: 'pet_detail_age_chip',
            label: pet.ageDisplay!,
            child: PetInfoChip(icon: Icons.cake, label: pet.ageDisplay!),
          ),
        if (weightChipLabel != null)
          PetInfoChip(
            icon: Icons.monitor_weight,
            label: weightChipLabel!,
          ),
      ],
    );
  }
}
