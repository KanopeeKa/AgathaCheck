import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/utils/constants.dart';
import '../../domain/entities/pet.dart';

/// A Material 3 card widget that displays a pet's summary information.
///
/// Shows the pet's photo (or a placeholder icon), name, breed,
/// and species. Tapping the card triggers [onTap].
class PetCard extends StatelessWidget {
  const PetCard({
    super.key,
    required this.pet,
    this.onTap,
  });

  final Pet pet;

  final VoidCallback? onTap;

  /// Builds the pet card with photo, name, breed, species, and delete action.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MergeSemantics(
      child: Semantics(
        label: 'Pet: ${pet.name}, ${pet.species}',
        child: Card(
          key: Key('pet_card_${pet.name}'),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildAvatar(colorScheme),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pet.breed.isNotEmpty
                              ? '${pet.species} - ${pet.breed}'
                              : pet.species,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (pet.ageDisplay != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${pet.ageDisplay!} old',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ExcludeSemantics(
                    child: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    final petColor = pet.colorValue != null
        ? Color(pet.colorValue!)
        : colorScheme.primary;

    Widget avatar;

    if (pet.photoPath != null && pet.photoPath!.isNotEmpty) {
      try {
        final bytes = base64Decode(pet.photoPath!);
        avatar = Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: petColor, width: 3),
          ),
          child: ClipOval(
            child: Image.memory(
              bytes,
              width: 62,
              height: 62,
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (_) {
        avatar = _buildPlaceholder(petColor);
      }
    } else {
      avatar = _buildPlaceholder(petColor);
    }

    if (pet.passedAway) {
      return ClipOval(
        child: SizedBox(
          width: 68,
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0xDDFFFFFF),
                  BlendMode.lighten,
                ),
                child: avatar,
              ),
              SizedBox(
                width: 50,
                height: 50,
                child: Opacity(
                  opacity: 0.35,
                  child: Image.asset(
                    'assets/rainbow_wings.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return avatar;
  }

  Widget _buildPlaceholder(Color petColor) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: petColor.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: petColor, width: 3),
      ),
      child: AppConstants.speciesIconWidget(pet.species, size: 32, color: petColor),
    );
  }

}
