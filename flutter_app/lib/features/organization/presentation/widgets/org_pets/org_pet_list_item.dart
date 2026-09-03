import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/presentation/utils/pet_tile_dimensions.dart';
import '../../../../pet_profile/presentation/widgets/unified_pet_tile.dart';
import '../../../domain/entities/foster_placement.dart';
import '../../models/org_pet_list_entry.dart';
import 'org_unified_pet_tile_helpers.dart';

class OrgPetListItem extends StatelessWidget {
  const OrgPetListItem({
    super.key,
    required this.entry,
    required this.orgId,
    required this.showAttentionReason,
    required this.tileWidth,
    this.placements = const [],
  });

  final OrgPetListEntry entry;
  final String orgId;
  final bool showAttentionReason;
  final double tileWidth;
  final List<FosterPlacement> placements;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (entry.isArchived) {
      return Card(
        key: Key('org_pet_archived_${entry.name}'),
        child: ListTile(
          leading: Icon(
            entry.isShadow ? Icons.layers_outlined : Icons.archive_outlined,
            color: colorScheme.primary,
          ),
          title: Text(entry.name),
          subtitle: Text(entry.isShadow ? l.frozenShadow : l.orgArchived),
          onTap: entry.isShadow && entry.archivedPet != null
              ? () => context.push(
                  '/o/orgs/$orgId/archived/${entry.archivedPet!.id}',
                )
              : null,
        ),
      );
    }

    final pet = entry.pet!;
    final tileHeight = PetTileDimensions.heightFor(context);
    final activePlacement = activePlacementForEntry(entry, placements);
    final statusLine = resolveOrgPetTileStatusLine(
      l: l,
      pet: pet,
      activePlacement: activePlacement,
      attentionReason: entry.attentionReason,
      includeAttentionReason: showAttentionReason,
    );

    return UnifiedPetTile(
      pet: pet,
      width: tileWidth,
      height: tileHeight,
      statusLine: statusLine,
      onTap: () => context.push('/pet/${pet.id}'),
    );
  }
}
