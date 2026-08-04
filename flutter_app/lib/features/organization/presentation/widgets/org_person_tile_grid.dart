import 'package:flutter/material.dart';

import '../../../pet_profile/presentation/widgets/pet_card.dart';
import 'org_person_tile.dart';

/// Wrapping grid of [OrgPersonTile] using pet-tile sizing helpers.
class OrgPersonTileGrid extends StatelessWidget {
  const OrgPersonTileGrid({super.key, required this.tiles, this.gridKey});

  final List<Widget> tiles;
  final Key? gridKey;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      key: gridKey,
      builder: (context, constraints) {
        final tileWidth = PetCard.tileWidthFor(constraints.maxWidth);
        final tileHeight = PetCard.tileHeightFor(constraints.maxWidth);

        return Wrap(
          spacing: PetCard.tileSpacing,
          runSpacing: PetCard.tileSpacing,
          children: [
            for (final tile in tiles)
              SizedBox(width: tileWidth, height: tileHeight, child: tile),
          ],
        );
      },
    );
  }
}

/// Sized [OrgPersonTile] for explicit layouts.
Widget sizedOrgPersonTile(BuildContext context, {required OrgPersonTile tile}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final tileWidth = PetCard.tileWidthFor(constraints.maxWidth);
      final tileHeight = PetCard.tileHeightFor(constraints.maxWidth);
      return SizedBox(width: tileWidth, height: tileHeight, child: tile);
    },
  );
}
