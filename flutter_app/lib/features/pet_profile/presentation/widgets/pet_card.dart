import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pet.dart';
import 'pet_tile_status_line.dart';
import 'unified_pet_tile.dart';

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

/// Legacy vertical pet tile — delegates rendering to [UnifiedPetTile].
///
/// Static layout helpers remain for grids and strips that predate unified tiles.
class PetCard extends StatelessWidget {
  const PetCard({super.key, required this.pet, this.onTap});

  final Pet pet;
  final VoidCallback? onTap;

  /// Spacing between tiles in [PetTileStrip] wrap/scroll layouts.
  static const double tileSpacing = 8;

  /// Target columns per row for wrap layouts at a given width.
  static int wrapColumnsFor(double maxWidth) {
    if (maxWidth >= 900) return 4;
    if (maxWidth >= 600) return 3;
    return 3;
  }

  static double _maxTileSizeFor(double maxWidth) {
    if (maxWidth >= 900) return 220;
    if (maxWidth >= 600) return 200;
    return double.infinity;
  }

  /// Tile width for available [maxWidth], fitting [wrapColumnsFor] per row.
  static double tileWidthFor(double maxWidth) {
    final columns = wrapColumnsFor(maxWidth);
    final computed = (maxWidth - (columns - 1) * tileSpacing) / columns;
    final maxSize = _maxTileSizeFor(maxWidth);
    return computed > maxSize ? maxSize : computed;
  }

  /// Tile height preserving the 1:1 aspect ratio ([tileWidthFor]).
  static double tileHeightFor(double maxWidth) => tileWidthFor(maxWidth);

  /// Square tile side length — same as [tileWidthFor].
  static double tileSizeFor(double maxWidth) => tileWidthFor(maxWidth);

  /// [PetCard] with responsive square constraints for list/section layouts.
  static Widget sizedTile(
    BuildContext context, {
    required Pet pet,
    VoidCallback? onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = tileWidthFor(constraints.maxWidth);
        final tileHeight = tileHeightFor(constraints.maxWidth);
        return SizedBox(
          width: tileWidth,
          height: tileHeight,
          child: PetCard(pet: pet, onTap: onTap),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : null;
        final height =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : null;
        return UnifiedPetTile(
          pet: pet,
          onTap: onTap,
          width: width,
          height: height,
          statusLine: const PetTileStatusLineData(label: ''),
          semanticsLabel: _semanticsLabel(l, pet),
        );
      },
    );
  }

  String _semanticsLabel(AppLocalizations l, Pet pet) {
    final species = _localizedSpecies(l, pet.species);
    if (pet.organizationName != null && pet.organizationName!.isNotEmpty) {
      return 'Pet: ${pet.name}, ${pet.organizationName}, $species';
    }
    return 'Pet: ${pet.name}, $species';
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

/// Responsive grid or strip of vertical [PetCard] tiles.
///
/// [useWrap] lays out all tiles in a wrapping grid (dashboard, manage-pets).
/// Otherwise uses a horizontal scroll strip.
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
        final tileHeight = PetCard.tileHeightFor(constraints.maxWidth);

        Widget buildTile(Pet pet) {
          final card = PetCard(pet: pet, onTap: () => onPetTap(pet));
          final wrapped = tileBuilder?.call(pet, card) ?? card;
          return SizedBox(width: tileWidth, height: tileHeight, child: wrapped);
        }

        if (useWrap) {
          return Wrap(
            spacing: PetCard.tileSpacing,
            runSpacing: PetCard.tileSpacing,
            children: pets.map(buildTile).toList(),
          );
        }

        return SizedBox(
          height: tileHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pets.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: PetCard.tileSpacing),
            itemBuilder: (context, index) => buildTile(pets[index]),
          ),
        );
      },
    );
  }
}
