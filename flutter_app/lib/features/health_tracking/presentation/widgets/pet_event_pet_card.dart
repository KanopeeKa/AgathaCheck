import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/widgets/pet_detail/pet_info_chip.dart';
import '../../../pet_profile/presentation/widgets/pet_photo_image.dart';

/// Pet thumbnail, name, and species badge for care event detail screens.
class PetEventPetCard extends ConsumerWidget {
  const PetEventPetCard({super.key, required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final apiBaseUrl = ref.watch(apiBaseUrlProvider);

    return Card(
      key: const Key('pet_event_pet_card'),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: ClipOval(
                child: buildPetPhotoOrPlaceholder(
                  photoPath: pet.photoPath,
                  apiBaseUrl: apiBaseUrl,
                  fit: BoxFit.cover,
                  semanticLabel: 'Photo of ${pet.name}',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (pet.species.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    PetInfoChipWidget(
                      iconWidget: AppConstants.speciesIconWidget(
                        pet.species,
                        size: 16,
                      ),
                      label: pet.species,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
