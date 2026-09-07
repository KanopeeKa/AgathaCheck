import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/api_base_url_provider.dart';
import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../core/utils/constants.dart';
import '../../../domain/entities/pet.dart';
import '../../utils/pet_accent_color.dart';
import '../pet_photo_image.dart';

/// Renders a pet's photo (or a species placeholder) for the profile card.
///
/// When the pet has passed away the photo is lightened and overlaid with the
/// rainbow-wings memorial image.
class PetPhoto extends ConsumerWidget {
  const PetPhoto({super.key, required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petColor = resolvePetAccentColor(context, pet);
    final apiBaseUrl = ref.watch(apiBaseUrlProvider);

    final image = buildPetPhotoImage(
      photoPath: pet.photoPath,
      apiBaseUrl: apiBaseUrl,
      fit: BoxFit.cover,
      semanticLabel: 'Photo of ${pet.name}',
      errorBuilder: (_, __, ___) => _buildPlaceholder(petColor),
    );

    final photoContent = image ?? _buildPlaceholder(petColor);

    if (pet.passedAway) {
      return ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                AppColorTokens.passedAwayPhotoOverlay,
                BlendMode.lighten,
              ),
              child: photoContent,
            ),
            Center(
              child: Opacity(
                opacity: 0.35,
                child: Image.asset(
                  'assets/rainbow_wings.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return photoContent;
  }

  Widget _buildPlaceholder(Color petColor) {
    return Container(
      color: petColor.withValues(alpha: 0.12),
      child: Center(
        child: AppConstants.speciesIconWidget(
          pet.species,
          size: 56,
          color: petColor.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
