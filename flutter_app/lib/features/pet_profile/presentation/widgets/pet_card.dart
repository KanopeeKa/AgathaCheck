import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pet.dart';
import '../utils/ownership_accent.dart';
import '../utils/pet_accent_color.dart';

/// Material card showing a pet summary with image, ownership status bar, and name.
///
/// Vertical layout (image → status bar → name) for dashboard grids and list rows.
class PetCard extends StatelessWidget {
  const PetCard({super.key, required this.pet, this.onTap});

  final Pet pet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final ownership = resolvePetOwnershipAccent(context, pet, l);
    final fosterAccent = fosterOwnershipAccentColor(context);
    final statusBarColor = pet.isFoster ? fosterAccent : ownership.accentColor;

    return MergeSemantics(
      child: Semantics(
        label: _semanticsLabel(l, pet),
        child: Card(
          key: Key('pet_card_${pet.name}'),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: _buildImageArea(context),
                ),
                Container(height: 4, color: statusBarColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (pet.organizationName != null &&
                          pet.organizationName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 12,
                              color: ownership.accentColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                pet.organizationName!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: ownership.accentColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (ownership.showsFosterLabel) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.home_work_outlined,
                              size: 12,
                              color: fosterAccent,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ownership.fosterLabel!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: fosterAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        _speciesLine(l, pet),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_hasExtraSubtitle(pet)) ...[
                        const SizedBox(height: 2),
                        Text(
                          _extraSubtitle(pet),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _semanticsLabel(AppLocalizations l, Pet pet) {
    final species = _localizedSpecies(l, pet.species);
    if (pet.organizationName != null && pet.organizationName!.isNotEmpty) {
      return 'Pet: ${pet.name}, ${pet.organizationName}, $species';
    }
    return 'Pet: ${pet.name}, $species';
  }

  bool _hasExtraSubtitle(Pet pet) {
    return pet.ageDisplay != null ||
        (pet.gender != null && pet.gender!.isNotEmpty);
  }

  String _speciesLine(AppLocalizations l, Pet pet) {
    final species = _localizedSpecies(l, pet.species);
    if (pet.breed.isNotEmpty) return '$species - ${pet.breed}';
    return species;
  }

  String _extraSubtitle(Pet pet) {
    return [
      if (pet.ageDisplay != null) '${pet.ageDisplay!} old',
      if (pet.gender != null && pet.gender!.isNotEmpty) pet.gender!,
    ].join(' · ');
  }

  Widget _buildImageArea(BuildContext context) {
    final petColor = resolvePetAccentColor(context, pet);
    Widget image = _buildPhotoOrPlaceholder(petColor);

    if (pet.passedAway) {
      image = Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              AppColorTokens.passedAwayPhotoOverlay,
              BlendMode.lighten,
            ),
            child: image,
          ),
          Center(
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                'assets/rainbow_wings.png',
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      );
    }

    return image;
  }

  Widget _buildPhotoOrPlaceholder(Color petColor) {
    if (pet.photoPath != null && pet.photoPath!.isNotEmpty) {
      try {
        final bytes = base64Decode(pet.photoPath!);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return _buildPlaceholder(petColor);
      }
    }
    return _buildPlaceholder(petColor);
  }

  Widget _buildPlaceholder(Color petColor) {
    return ColoredBox(
      color: petColor.withValues(alpha: 0.12),
      child: Center(
        child: AppConstants.speciesIconWidget(
          pet.species,
          size: 40,
          color: petColor,
        ),
      ),
    );
  }
}

String _localizedSpecies(AppLocalizations l, String species) {
  switch (species) {
    case 'Dog':
      return l.speciesDog;
    case 'Cat':
      return l.speciesCat;
    case 'Bird':
      return l.speciesBird;
    case 'Fish':
      return l.speciesFish;
    case 'Rabbit':
      return l.speciesRabbit;
    case 'Hamster':
      return l.speciesHamster;
    case 'Ferret':
      return l.speciesFerret;
    case 'Horse / Poney':
      return l.speciesHorsePoney;
    case 'Other':
      return l.speciesOther;
    default:
      return species;
  }
}

/// Responsive grid of [PetCard] widgets (2 columns mobile, 3 on wider screens).
class PetCardGrid extends StatelessWidget {
  const PetCardGrid({super.key, required this.pets, required this.onPetTap});

  final List<Pet> pets;
  final void Function(Pet pet) onPetTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 520 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.72,
          ),
          itemCount: pets.length,
          itemBuilder: (context, index) {
            final pet = pets[index];
            return PetCard(pet: pet, onTap: () => onPetTap(pet));
          },
        );
      },
    );
  }
}
