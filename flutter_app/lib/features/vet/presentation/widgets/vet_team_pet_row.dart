import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/router/shell_return_navigation.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/widgets/pet_photo_image.dart';

/// Flat, tappable pet row for the care team detail screen.
class VetTeamPetRow extends StatelessWidget {
  const VetTeamPetRow({super.key, required this.pet, this.showDivider = true});

  final Pet pet;
  final bool showDivider;

  static const double _avatarSize = 40;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: pet.name,
          onTap: () => openPetDetail(context, pet.id),
          excludeSemantics: true,
          child: InkWell(
            onTap: () => openPetDetail(context, pet.id),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ExcludeSemantics(child: _PetAvatar(pet: pet)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        pet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ExcludeSemantics(
                      child: Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}

class _PetAvatar extends ConsumerWidget {
  const _PetAvatar({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiBaseUrl = ref.watch(apiBaseUrlProvider);

    return SizedBox(
      width: VetTeamPetRow._avatarSize,
      height: VetTeamPetRow._avatarSize,
      child: ClipOval(
        child: buildPetPhotoOrPlaceholder(
          photoPath: pet.photoPath,
          apiBaseUrl: apiBaseUrl,
          fit: BoxFit.cover,
          semanticLabel: pet.name,
        ),
      ),
    );
  }
}
