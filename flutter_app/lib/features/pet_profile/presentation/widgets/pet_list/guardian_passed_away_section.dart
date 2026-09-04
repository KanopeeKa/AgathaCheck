import 'package:flutter/material.dart';

import '../../../../experience/presentation/screens/guardian/guardian_dashboard_helpers.dart';
import '../../../../experience/presentation/widgets/guardian_pets_tile_grid.dart';
import '../../../domain/entities/pet.dart';
import '../pet_card.dart';

/// Collapsed passed-away section for the embedded Guardian All Pets shell.
///
/// Renders passed-away pets with [UnifiedPetTile] (wings overlay) inside an
/// [ExpansionTile] collapsed by default.
class GuardianPassedAwaySection extends StatelessWidget {
  const GuardianPassedAwaySection({
    super.key,
    required this.pets,
    required this.title,
    required this.onPetTap,
    this.careSummary,
  });

  final List<Pet> pets;
  final String title;
  final ValueChanged<Pet> onPetTap;
  final GuardianTodayCareSummary? careSummary;

  @override
  Widget build(BuildContext context) {
    if (pets.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final sorted = [...pets];
    sortPetsByCreatedAt(sorted);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: ExpansionTile(
          key: const Key('guardian_passed_away_section'),
          initiallyExpanded: false,
          leading: Icon(
            Icons.favorite,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${sorted.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: GuardianPetsTileGrid(
                pets: sorted,
                careSummary: careSummary,
                onPetTap: onPetTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
