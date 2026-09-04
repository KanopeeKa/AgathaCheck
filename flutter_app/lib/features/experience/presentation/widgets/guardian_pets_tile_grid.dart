import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/utils/pet_tile_dimensions.dart';
import '../../../pet_profile/presentation/widgets/pet_card.dart'
    show sortPetsByCreatedAt;
import '../../../pet_profile/presentation/widgets/pet_tile_status_line.dart';
import '../../../pet_profile/presentation/widgets/unified_pet_tile.dart';
import '../screens/guardian/guardian_dashboard_helpers.dart';

/// Dashboard-aligned unified pet tiles in a responsive wrap grid for guardian list screens.
class GuardianPetsTileGrid extends StatelessWidget {
  const GuardianPetsTileGrid({
    super.key,
    required this.pets,
    required this.careSummary,
    required this.onPetTap,
    this.selectionMode = false,
    this.selectedPetIds = const {},
    this.onToggleSelection,
  });

  final List<Pet> pets;
  final GuardianTodayCareSummary? careSummary;
  final ValueChanged<Pet> onPetTap;
  final bool selectionMode;
  final Set<String> selectedPetIds;
  final ValueChanged<Pet>? onToggleSelection;

  static const double _spacing = 12;

  static int columnsForWidth(double width) {
    if (width >= 900) return 3;
    return 2;
  }

  static double tileWidthFor(double maxWidth) {
    final columns = columnsForWidth(maxWidth);
    final computed = (maxWidth - (columns - 1) * _spacing) / columns;
    final target = PetTileDimensions.widthFor(maxWidth);
    return computed.clamp(PetTileDimensions.minWidth, target);
  }

  @override
  Widget build(BuildContext context) {
    if (pets.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final sorted = [...pets];
    sortPetsByCreatedAt(sorted);
    final tileHeight = PetTileDimensions.heightFor(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = tileWidthFor(constraints.maxWidth);
        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final pet in sorted)
              SizedBox(
                width: tileWidth,
                child: _tileFor(
                  context,
                  pet: pet,
                  l: l,
                  tileWidth: tileWidth,
                  tileHeight: tileHeight,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _tileFor(
    BuildContext context, {
    required Pet pet,
    required AppLocalizations l,
    required double tileWidth,
    required double tileHeight,
  }) {
    final theme = Theme.of(context);
    final careState = careSummary == null
        ? GuardianTodayPetCareState.clear
        : guardianTodayPetCareState(pet, careSummary!);
    final statusLine = resolvePetTileStatusLine(
      l: l,
      pet: pet,
      context: PetTileContext.petCare,
      careUrgency: petTileCareUrgencyFor(careState),
    );
    final selected = selectedPetIds.contains(pet.id);

    final tile = UnifiedPetTile(
      pet: pet,
      width: tileWidth,
      height: tileHeight,
      statusLine: statusLine,
      onTap: () {
        if (selectionMode) {
          onToggleSelection?.call(pet);
        } else {
          onPetTap(pet);
        }
      },
    );

    if (!selectionMode) return tile;

    return Semantics(
      selected: selected,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          tile,
          if (selected)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 6,
            right: 6,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface.withValues(alpha: 0.92),
              foregroundColor: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
              child: Icon(
                selected ? Icons.check : Icons.circle_outlined,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
