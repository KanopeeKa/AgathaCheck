import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/core/router/shell_return_navigation.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Block 1 — pet rail, linked care name, dose context (CARE-ITEM-R-017).
class OccurrenceCareContextCard extends ConsumerWidget {
  const OccurrenceCareContextCard({
    super.key,
    required this.detail,
    required this.onOpenCareDetails,
  });

  final OccurrenceDetail detail;
  final VoidCallback onOpenCareDetails;

  static const double _familyChipSize = 52;
  static const double _petAvatarSize = 48;
  static const double _leftRailWidth = 88;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final item = detail.item;
    final petAsync = ref.watch(petByIdProvider(item.petId));
    final family = CareFamilyWire.fromWire(item.careFamily) ?? CareFamily.other;
    final familyLabel = careFamilyLabel(l, family);

    return Semantics(
      identifier: 'occurrence_care_context_card',
      container: true,
      child: CareItemModule(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _leftRailWidth,
              child: petAsync.when(
                loading: () => const SizedBox(
                  width: _petAvatarSize,
                  height: _petAvatarSize,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (pet) => pet == null
                    ? const SizedBox.shrink()
                    : _PetRailAvatar(pet: pet),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    identifier: 'occurrence_care_name_link',
                    button: true,
                    label: l.occurrenceOpenCareDetails,
                    child: InkWell(
                      onTap: onOpenCareDetails,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          item.name,
                          key: const Key('occurrence_care_name_link'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (item.doseLine != null && item.doseLine!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.doseLine!,
                      key: const Key('occurrence_dose_line'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  if (item.strengthFormLine != null &&
                      item.strengthFormLine!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.strengthFormLine!,
                      key: const Key('occurrence_strength_form_line'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: _leftRailWidth,
              child: Column(
                children: [
                  CareFamilyIcon(
                    family: family,
                    showChip: true,
                    chipSize: _familyChipSize,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    familyLabel,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetRailAvatar extends ConsumerWidget {
  const _PetRailAvatar({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final apiBaseUrl = ref.watch(apiBaseUrlProvider);

    return Semantics(
      button: true,
      label: pet.name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openPetDetail(context, pet.id),
          customBorder: const CircleBorder(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: OccurrenceCareContextCard._petAvatarSize,
                height: OccurrenceCareContextCard._petAvatarSize,
                child: ClipOval(
                  child: buildPetPhotoOrPlaceholder(
                    photoPath: pet.photoPath,
                    apiBaseUrl: apiBaseUrl,
                    fit: BoxFit.cover,
                    semanticLabel: 'Photo of ${pet.name}',
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pet.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
