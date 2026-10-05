import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import '../../domain/entities/health_entry.dart';

/// Lightweight circular pet photo for [CareEventRow] leading slot.
class CareEventRowPetAvatar extends ConsumerWidget {
  const CareEventRowPetAvatar({super.key, this.pet, this.petName});

  final Pet? pet;
  final String? petName;

  static const size = 32.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiBaseUrl = ref.watch(apiBaseUrlProvider);

    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: buildPetPhotoOrPlaceholder(
            photoPath: pet?.photoPath,
            apiBaseUrl: apiBaseUrl,
            fit: BoxFit.cover,
            semanticLabel: pet?.name,
          ),
        ),
      ),
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
