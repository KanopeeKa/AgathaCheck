import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/core/router/shell_return_navigation.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

/// Compact pet chip for the Care Item context strip (not [UnifiedPetTile]).
class CareItemPetContextTile extends ConsumerWidget {
  const CareItemPetContextTile({super.key, required this.pet});

  final Pet pet;

  static const double avatarSize = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final apiBaseUrl = ref.watch(apiBaseUrlProvider);

    return Semantics(
      identifier: 'care_item_pet_tile',
      button: true,
      label: pet.name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openPetDetail(context, pet.id),
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: avatarSize,
                  height: avatarSize,
                  child: ClipOval(
                    child: buildPetPhotoOrPlaceholder(
                      photoPath: pet.photoPath,
                      apiBaseUrl: apiBaseUrl,
                      fit: BoxFit.cover,
                      semanticLabel: 'Photo of ${pet.name}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    pet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
