import 'package:flutter/material.dart';

import '../../../../../core/utils/constants.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/pet.dart';
import 'pet_info_chip.dart';
import 'pet_photo.dart';

/// Live preview card for the desktop pet form — photo, name, and quick-info chips.
class PetFormPreviewCard extends StatelessWidget {
  const PetFormPreviewCard({
    super.key,
    required this.pet,
    required this.displayName,
    this.weightLabel,
  });

  final Pet pet;
  final String displayName;
  final String? weightLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final name = displayName.trim().isEmpty ? l.petName : displayName.trim();
    final species = pet.species.trim().isEmpty ? l.speciesDog : pet.species;

    return Card(
      key: const Key('pet_form_preview_card'),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 160,
                  height: 160,
                  child: PetPhoto(pet: pet),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                PetInfoChipWidget(
                  iconWidget: AppConstants.speciesIconWidget(species, size: 18),
                  label: species,
                ),
                if (pet.gender != null && pet.gender!.isNotEmpty)
                  PetInfoChip(
                    icon: pet.gender == 'Male' ? Icons.male : Icons.female,
                    label: pet.gender!,
                  ),
                if (pet.ageDisplay != null)
                  PetInfoChip(icon: Icons.cake, label: pet.ageDisplay!),
                if (weightLabel != null && weightLabel!.isNotEmpty)
                  PetInfoChip(icon: Icons.monitor_weight, label: weightLabel!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
