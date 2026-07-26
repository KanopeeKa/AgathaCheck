import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pet.dart';
import '../utils/ownership_accent.dart';
import '../utils/pet_accent_color.dart';

/// Sort pets oldest-first (creation order), then by name.
void sortPetsByCreatedAt(List<Pet> pets) {
  pets.sort((a, b) {
    final ad = a.createdAt ?? DateTime(2100);
    final bd = b.createdAt ?? DateTime(2100);
    final byDate = ad.compareTo(bd);
    if (byDate != 0) return byDate;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
}

/// Horizontal dashboard tile: 2/3 image, 1/3 text, fixed height.
class PetCard extends StatelessWidget {
  const PetCard({super.key, required this.pet, this.onTap});

  final Pet pet;
  final VoidCallback? onTap;

  static const tileHeight = 100.0;

  static double tileWidthFor(double maxWidth) {
    if (maxWidth >= 900) return 220;
    if (maxWidth >= 600) return 200;
    if (maxWidth >= 400) return 180;
    return 160;
  }

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
        identifier: 'pet_card',
        label: _semanticsLabel(l, pet),
        child: Card(
          key: Key('pet_card_${pet.name}'),
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: tileHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: statusBarColor),
                  Expanded(flex: 2, child: _buildImageArea(context)),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            pet.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (ownership.showsFosterLabel) ...[
                            const SizedBox(height: 2),
                            Text(
                              ownership.fosterLabel!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: fosterAccent,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            _speciesLine(l, pet),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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

  String _semanticsLabel(AppLocalizations l, Pet pet) {
    final species = _localizedSpecies(l, pet.species);
    if (pet.organizationName != null && pet.organizationName!.isNotEmpty) {
      return 'Pet: ${pet.name}, ${pet.organizationName}, $species';
    }
    return 'Pet: ${pet.name}, $species';
  }

  String _speciesLine(AppLocalizations l, Pet pet) {
    final species = _localizedSpecies(l, pet.species);
    if (pet.breed.isNotEmpty) return '$species · ${pet.breed}';
    return species;
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
                width: 36,
                height: 36,
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
          size: 32,
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

/// Responsive row of horizontal [PetCard] tiles.
///
/// [useWrap] lays out all tiles in a wrapping grid (manage-pets screen).
/// Otherwise uses a horizontal scroll strip (dashboard groups).
class PetTileStrip extends StatelessWidget {
  const PetTileStrip({
    super.key,
    required this.pets,
    required this.onPetTap,
    this.useWrap = false,
    this.tileBuilder,
  });

  final List<Pet> pets;
  final void Function(Pet pet) onPetTap;

  /// When true, tiles wrap to multiple rows instead of horizontal scroll.
  final bool useWrap;

  /// Optional wrapper (e.g. bulk-share checkbox overlay).
  final Widget Function(Pet pet, Widget tile)? tileBuilder;

  @override
  Widget build(BuildContext context) {
    if (pets.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = PetCard.tileWidthFor(constraints.maxWidth);

        Widget buildTile(Pet pet) {
          final card = PetCard(pet: pet, onTap: () => onPetTap(pet));
          final wrapped = tileBuilder?.call(pet, card) ?? card;
          return SizedBox(
            width: tileWidth,
            height: PetCard.tileHeight,
            child: wrapped,
          );
        }

        if (useWrap) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pets.map(buildTile).toList(),
          );
        }

        return SizedBox(
          height: PetCard.tileHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) => buildTile(pets[index]),
          ),
        );
      },
    );
  }
}
