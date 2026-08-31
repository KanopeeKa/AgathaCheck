import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/vet.dart';
import '../utils/vet_accent.dart';
import 'care_team_initials_avatar.dart';
import 'linked_pet_avatar_stack.dart';

/// Warm, relational care-team card for the guardian dashboard.
class CareTeamCard extends StatelessWidget {
  const CareTeamCard({
    super.key,
    required this.vet,
    required this.linkedPets,
    required this.linkedPetCount,
    required this.onTap,
    this.showChevron = true,
  });

  final Vet vet;

  /// Linked pets for avatar preview; empty when none or still loading.
  final List<Pet> linkedPets;

  /// Null while pet list is loading — never show a false zero count.
  final int? linkedPetCount;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final town = vetTownLabel(vet.address);
    final subtitle = town.isEmpty
        ? l.careTeamClinicSubtitle
        : '${l.careTeamClinicSubtitle} · $town';
    final caringLabel = linkedPetCount == null
        ? null
        : l.careTeamCaringForPets(linkedPetCount!);
    final semanticLabel = [
      vet.name,
      subtitle,
      if (caringLabel != null) caringLabel,
    ].join(', ');

    final previewPets = linkedPets
        .take(LinkedPetAvatarStack.maxVisible)
        .toList();
    final total = linkedPetCount ?? 0;
    final overflowCount = total > LinkedPetAvatarStack.maxVisible
        ? total - LinkedPetAvatarStack.maxVisible
        : 0;
    final showPetRow =
        caringLabel != null &&
        linkedPetCount! > 0 &&
        (previewPets.isNotEmpty || overflowCount > 0);

    return Semantics(
      key: Key('care_team_card_${vet.id}'),
      button: true,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: theme.colorScheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CareTeamInitialsAvatar(
                      name: vet.name,
                      organizationId: vet.organizationId,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vet.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (showPetRow) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                LinkedPetAvatarStack(
                                  pets: previewPets,
                                  overflowCount: overflowCount,
                                ),
                                if (previewPets.isNotEmpty || overflowCount > 0)
                                  const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    caringLabel!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (caringLabel != null &&
                              linkedPetCount! > 0 &&
                              previewPets.isEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              caringLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (showChevron) ...[
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
