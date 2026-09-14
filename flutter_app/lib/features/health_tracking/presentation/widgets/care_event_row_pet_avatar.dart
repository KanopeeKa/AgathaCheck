import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/utils/pet_accent_color.dart';
import '../../../pet_profile/presentation/widgets/pet_photo_image.dart';
import '../../domain/entities/health_entry.dart';

/// Lightweight circular pet photo for [CareEventRow] leading slot.
///
/// Uses [buildPetPhotoImage] so server `/uploads/` paths and asset URIs render
/// correctly — not only inline base64.
class CareEventRowPetAvatar extends ConsumerWidget {
  const CareEventRowPetAvatar({
    super.key,
    this.pet,
    this.petName,
    required this.colorScheme,
  });

  final Pet? pet;
  final String? petName;
  final ColorScheme colorScheme;

  static const size = 32.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petColor = pet != null
        ? resolvePetAccentColor(context, pet!)
        : colorScheme.surfaceContainerHighest;
    final apiBaseUrl = ref.watch(apiBaseUrlProvider);

    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: _buildAvatar(petColor, apiBaseUrl),
      ),
    );
  }

  Widget _buildAvatar(Color petColor, String apiBaseUrl) {
    final photoPath = pet?.photoPath;
    if (photoPath != null && photoPath.isNotEmpty) {
      final image = buildPetPhotoImage(
        photoPath: photoPath,
        apiBaseUrl: apiBaseUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(petColor),
      );
      if (image != null) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: petColor, width: 1.5),
          ),
          child: ClipOval(child: image),
        );
      }
    }

    return _placeholder(petColor);
  }

  Widget _placeholder(Color petColor) {
    final species = pet?.species ?? '';
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: petColor.withValues(alpha: 0.22),
        border: Border.all(color: petColor, width: 1.5),
      ),
      child: species.isNotEmpty
          ? Center(
              child: AppConstants.speciesIconWidget(
                species,
                size: 16,
                color: petColor,
              ),
            )
          : Icon(Icons.pets, size: 16, color: petColor),
    );
  }
}

String careEventRowDisplayPetName(
  Pet? pet,
  HealthEntry entry,
  AppLocalizations l,
) {
  final fromPet = pet?.name;
  if (fromPet != null && fromPet.isNotEmpty) return fromPet;
  final fromEntry = entry.petName;
  if (fromEntry != null && fromEntry.isNotEmpty) return fromEntry;
  return l.unknownPet;
}
