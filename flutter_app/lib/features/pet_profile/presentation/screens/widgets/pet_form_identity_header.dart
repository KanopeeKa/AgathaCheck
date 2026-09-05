import 'package:flutter/material.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/pet.dart';
import '../../widgets/pet_detail/pet_photo.dart';

/// Photo identity header for the add/edit pet form.
class PetFormIdentityHeader extends StatelessWidget {
  const PetFormIdentityHeader({
    super.key,
    required this.pet,
    required this.onChangePhoto,
  });

  final Pet pet;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 120, height: 120, child: PetPhoto(pet: pet)),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          key: const Key('pet_change_photo_button'),
          onPressed: onChangePhoto,
          icon: const Icon(
            Icons.camera_alt_outlined,
            color: AppColorTokens.petCarePrimary,
          ),
          label: Text(
            l.petFormChangePhoto,
            style: const TextStyle(color: AppColorTokens.petCarePrimary),
          ),
        ),
      ],
    );
  }
}
