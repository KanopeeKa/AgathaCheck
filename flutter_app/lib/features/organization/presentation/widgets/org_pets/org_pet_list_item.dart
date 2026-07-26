import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/presentation/widgets/pet_card.dart';
import '../../models/org_pet_list_entry.dart';
import '../../utils/org_pets_care_utils.dart';
import 'org_pets_filter_row.dart';

class OrgPetListItem extends StatelessWidget {
  const OrgPetListItem({
    super.key,
    required this.entry,
    required this.orgId,
    required this.isOrgAdmin,
    required this.showAttentionReason,
  });

  final OrgPetListEntry entry;
  final String orgId;
  final bool isOrgAdmin;
  final bool showAttentionReason;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PetCard(pet: pet, onTap: () => context.push('/pet/${pet.id}')),
        if (showAttentionReason && entry.attentionReason != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              localizedAttentionReason(l, entry.attentionReason!),
              key: Key('org_pet_attention_${pet.name}'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (isOrgAdmin)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  key: Key('org_transfer_pet_${pet.id}'),
                  onPressed: () =>
                      context.push('/o/orgs/$orgId/transfer/${pet.id}'),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: Text(l.transferPet),
                ),
                TextButton.icon(
                  key: Key('org_transfer_org_${pet.id}'),
                  onPressed: () =>
                      context.push('/o/orgs/$orgId/transfer/${pet.id}/to-org'),
                  icon: const Icon(Icons.hub_outlined, size: 18),
                  label: Text(l.transferToOrganisation),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
