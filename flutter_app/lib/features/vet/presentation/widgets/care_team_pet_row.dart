import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/constants.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/utils/pet_accent_color.dart';

/// Flat, tappable pet row for the care team detail screen.
class CareTeamPetRow extends StatelessWidget {
  const CareTeamPetRow({
    super.key,
    required this.pet,
    this.showDivider = true,
  });

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
          onTap: () => context.go('/pet/${pet.id}'),
          excludeSemantics: true,
          child: InkWell(
            onTap: () => context.go('/pet/${pet.id}'),
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

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final petColor = resolvePetAccentColor(context, pet);

    return SizedBox(
      width: CareTeamPetRow._avatarSize,
      height: CareTeamPetRow._avatarSize,
      child: ClipOval(child: _buildImage(petColor)),
    );
  }

  Widget _buildImage(Color petColor) {
    if (pet.photoPath?.startsWith('asset://') ?? false) {
      return Image.asset(
        pet.photoPath!.substring('asset://'.length),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(petColor),
      );
    }
    if (pet.photoPath != null && pet.photoPath!.isNotEmpty) {
      try {
        var data = pet.photoPath!;
        if (data.contains(',')) {
          data = data.split(',').last;
        }
        final bytes = base64Decode(data);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return _placeholder(petColor);
      }
    }
    return _placeholder(petColor);
  }

  Widget _placeholder(Color petColor) {
    return ColoredBox(
      color: petColor.withValues(alpha: 0.12),
      child: Center(
        child: AppConstants.speciesIconWidget(
          pet.species,
          size: 22,
          color: petColor,
        ),
      ),
    );
  }
}
