import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../core/utils/constants.dart';
import '../../../domain/entities/pet.dart';
import '../../utils/pet_accent_color.dart';

/// Renders a pet's photo (or a species placeholder) for the profile card.
///
/// When the pet has passed away the photo is lightened and overlaid with the
/// rainbow-wings memorial image.
class PetPhoto extends StatelessWidget {
  const PetPhoto({super.key, required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final petColor = resolvePetAccentColor(context, pet);

    Widget photoContent;

    if (pet.photoPath != null && pet.photoPath!.isNotEmpty) {
      try {
        final bytes = base64Decode(pet.photoPath!);
        photoContent = Image.memory(
          bytes,
          fit: BoxFit.cover,
          semanticLabel: 'Photo of ${pet.name}',
        );
      } catch (_) {
        photoContent = _buildPlaceholder(petColor);
      }
    } else {
      photoContent = _buildPlaceholder(petColor);
    }

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
