import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/utils/pet_accent_color.dart';
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
    final petColor = resolvePetAccentColor(context, pet);
    final apiBaseUrl = ref.watch(apiBaseUrlProvider);

    return Card(
      key: const Key('pet_event_pet_card'),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _PetAvatar(pet: pet, petColor: petColor, apiBaseUrl: apiBaseUrl),
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

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({
    required this.pet,
    required this.petColor,
    required this.apiBaseUrl,
  });

  final Pet pet;
  final Color petColor;
  final String apiBaseUrl;

  static const _size = 48.0;

  @override
  Widget build(BuildContext context) {
    final image = buildPetPhotoImage(
      photoPath: pet.photoPath,
      apiBaseUrl: apiBaseUrl,
      fit: BoxFit.cover,
      semanticLabel: 'Photo of ${pet.name}',
      errorBuilder: (_, __, ___) => _placeholder(),
    );

    if (image != null) {
      return Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: petColor, width: 2),
        ),
        child: ClipOval(child: image),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: petColor.withValues(alpha: 0.2),
        border: Border.all(color: petColor, width: 2),
      ),
      child: pet.species.isNotEmpty
          ? Center(
              child: AppConstants.speciesIconWidget(
                pet.species,
                size: 24,
                color: petColor,
              ),
            )
          : Icon(Icons.pets, color: petColor),
    );
  }
}
