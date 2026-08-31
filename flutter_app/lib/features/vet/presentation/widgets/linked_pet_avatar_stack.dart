import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/utils/constants.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/utils/pet_accent_color.dart';

/// Compact overlapping pet avatars for care-team relationship previews.
class LinkedPetAvatarStack extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (pets.isEmpty && overflowCount <= 0) {
      return const SizedBox.shrink();
    }

    final visible = pets.take(maxVisible).toList(growable: false);
    final stackWidth = visible.isEmpty
        ? avatarSize
        : avatarSize + (visible.length - 1) * (avatarSize - overlap) +
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
                child: _PetMiniAvatar(pet: visible[i], size: avatarSize),
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
  const _PetMiniAvatar({required this.pet, required this.size});

  final Pet pet;
  final double size;

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
    if (pet.photoPath?.startsWith('asset://') ?? false) {
      return Image.asset(
        pet.photoPath!.substring('asset://'.length),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(color),
      );
    }
    if (pet.photoPath?.isNotEmpty ?? false) {
      try {
        return Image.memory(base64Decode(pet.photoPath!), fit: BoxFit.cover);
      } catch (_) {
        return _placeholder(color);
      }
    }
    return _placeholder(color);
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
