import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/utils/constants.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/utils/pet_accent_color.dart';
import '../../../pet_profile/presentation/widgets/pet_photo_image.dart';

/// Compact overlapping pet avatars for care-team relationship previews.
class LinkedPetAvatarStack extends ConsumerWidget {
  const LinkedPetAvatarStack({
    super.key,
    required this.pets,
    required this.overflowCount,
    this.avatarSize = 24,
  });

  final List<Pet> pets;
  final int overflowCount;
  final double avatarSize;

  static const maxVisible = 3;
  static const overlap = 8.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pets.isEmpty && overflowCount <= 0) {
      return const SizedBox.shrink();
    }

    final apiBaseUrl = ref.watch(apiBaseUrlProvider);
    final visible = pets.take(maxVisible).toList(growable: false);
    final stackWidth = visible.isEmpty
        ? avatarSize
        : avatarSize +
              (visible.length - 1) * (avatarSize - overlap) +
              (overflowCount > 0 ? (avatarSize - overlap) : 0);

    return ExcludeSemantics(
      child: SizedBox(
        width: stackWidth,
        height: avatarSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < visible.length; i++)
              Positioned(
                left: i * (avatarSize - overlap),
                child: _PetMiniAvatar(
                  pet: visible[i],
                  size: avatarSize,
                  apiBaseUrl: apiBaseUrl,
                ),
              ),
            if (overflowCount > 0)
              Positioned(
                left: visible.length * (avatarSize - overlap),
                child: _OverflowBadge(count: overflowCount, size: avatarSize),
              ),
          ],
        ),
      ),
    );
  }
}

class _PetMiniAvatar extends StatelessWidget {
  const _PetMiniAvatar({
    required this.pet,
    required this.size,
    required this.apiBaseUrl,
  });

  final Pet pet;
  final double size;
  final String apiBaseUrl;

  @override
  Widget build(BuildContext context) {
    final color = resolvePetAccentColor(context, pet);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: _photo(color),
    );
  }

  Widget _photo(Color color) {
    final image = buildPetPhotoImage(
      photoPath: pet.photoPath,
      apiBaseUrl: apiBaseUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(color),
    );
    return image ?? _placeholder(color);
  }

  Widget _placeholder(Color color) {
    return ColoredBox(
      color: color.withValues(alpha: 0.12),
      child: Center(
        child: AppConstants.speciesIconWidget(
          pet.species,
          size: size * 0.55,
          color: color,
        ),
      ),
    );
  }
}

class _OverflowBadge extends StatelessWidget {
  const _OverflowBadge({required this.count, required this.size});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        '+$count',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
