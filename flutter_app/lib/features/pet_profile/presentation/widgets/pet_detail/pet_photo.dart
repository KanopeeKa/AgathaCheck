import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/api_base_url_provider.dart';
import '../../../../../core/theme/app_color_tokens.dart';
import '../../../domain/entities/pet.dart';
import '../pet_photo_image.dart';

/// Renders a pet's photo (or the default illustration) for the profile card.
///
/// When the pet has passed away the photo is lightened and overlaid with the
/// rainbow-wings memorial image.
class PetPhoto extends ConsumerWidget {
  const PetPhoto({super.key, required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiBaseUrl = ref.watch(apiBaseUrlProvider);

    final photoContent = buildPetPhotoOrPlaceholder(
      photoPath: pet.photoPath,
      apiBaseUrl: apiBaseUrl,
      fit: BoxFit.cover,
      semanticLabel: 'Photo of ${pet.name}',
    );

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
}
