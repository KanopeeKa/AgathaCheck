import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../vet/presentation/widgets/vet_team_initials_avatar.dart';
import '../../domain/entities/person_roster_entry.dart';

/// Directory card aligned with [VetTeamCard] styling for People hub and desk.
class PeopleDirectoryCard extends StatelessWidget {
  const PeopleDirectoryCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.showChevron = true,
    this.linkedPetPreviewCount = 0,
  });

  final PersonRosterEntry entry;
  final VoidCallback onTap;
  final bool showChevron;
  final int linkedPetPreviewCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final subtitle = entry.roleLine;
    final caringLabel = entry.linkedPetCount == null
        ? null
        : l.peopleDeskLinkedPets(entry.linkedPetCount!);
    final semanticLabel = [
      entry.displayName,
      if (subtitle.isNotEmpty) subtitle,
      if (entry.statusLabel != null) entry.statusLabel!,
      if (caringLabel != null) caringLabel,
    ].join(', ');

    return Semantics(
      key: Key('people_directory_card_${entry.id}'),
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
            side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.35)),
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
                    VetTeamInitialsAvatar(
                      name: entry.displayName,
                      organizationId: null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (entry.statusLabel != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              entry.statusLabel!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (caringLabel != null &&
                              entry.linkedPetCount! > 0) ...[
                            const SizedBox(height: 6),
                            Text(
                              caringLabel,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (showChevron)
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
