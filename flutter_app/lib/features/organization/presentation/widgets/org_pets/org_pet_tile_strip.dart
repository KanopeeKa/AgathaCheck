import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/utils/pet_tile_dimensions.dart';
import '../../../../pet_profile/presentation/widgets/unified_pet_tile.dart';
import '../../../domain/entities/foster_placement.dart';
import '../../utils/org_pets_care_utils.dart';
import 'org_unified_pet_tile_helpers.dart';

/// Shelter org pet grid / strip using [UnifiedPetTile] at target dimensions.
class OrgPetTileStrip extends StatelessWidget {
  const OrgPetTileStrip({
    super.key,
    required this.pets,
    required this.onPetTap,
    this.useWrap = false,
    this.placements = const [],
  });

  final List<Pet> pets;
  final void Function(Pet pet) onPetTap;
  final bool useWrap;
  final List<FosterPlacement> placements;

  static const double tileSpacing = 8;

  @override
  Widget build(BuildContext context) {
    if (pets.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = PetTileDimensions.widthFor(constraints.maxWidth);
        final tileHeight = PetTileDimensions.heightFor(context);

        Widget buildTile(Pet pet) {
          final placement = activePlacementForPet(placements, pet.id);
          final statusLine = resolveOrgPetTileStatusLine(
            l: l,
            pet: pet,
            activePlacement: placement,
          );
          return UnifiedPetTile(
            pet: pet,
            width: tileWidth,
            height: tileHeight,
            statusLine: statusLine,
            onTap: () => onPetTap(pet),
          );
        }

        if (useWrap) {
          return Wrap(
            spacing: tileSpacing,
            runSpacing: tileSpacing,
            children: pets.map(buildTile).toList(),
          );
        }

        return SizedBox(
          height: tileHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pets.length,
            separatorBuilder: (_, __) => const SizedBox(width: tileSpacing),
            itemBuilder: (context, index) => buildTile(pets[index]),
          ),
        );
      },
    );
  }
}
