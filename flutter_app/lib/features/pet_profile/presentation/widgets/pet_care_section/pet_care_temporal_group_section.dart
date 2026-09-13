import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../pet_care/domain/care_temporal_group.dart';
import 'pet_care_action_row_builder.dart';
import 'pet_care_temporal_group_labels.dart';

/// One temporal group header plus its care item rows.
class PetCareTemporalGroupSection extends StatelessWidget {
  const PetCareTemporalGroupSection({
    super.key,
    required this.group,
    required this.entries,
    required this.establishedEntryIds,
    required this.trailingLabel,
    required this.onMarkDone,
    required this.onViewEntry,
  });

  final CareTemporalGroup group;
  final List<HealthEntry> entries;
  final Set<String> establishedEntryIds;
  final String trailingLabel;
  final void Function(HealthEntry entry) onMarkDone;
  final void Function(HealthEntry entry) onViewEntry;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final groupLabel = petCareTemporalGroupLabel(l10n, group);
    final groupIcon = petCareTemporalGroupIcon(group);

    return Column(
      key: Key('pet_care_group_${group.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          label: groupLabel,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(groupIcon, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  groupLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          PetCareActionRowBuilder(
            entry: entries[i],
            l10n: l10n,
            colorScheme: colorScheme,
            isEstablished: establishedEntryIds.contains(entries[i].id),
            trailingLabel: trailingLabel,
            onMarkDone: () => onMarkDone(entries[i]),
            onTap: () => onViewEntry(entries[i]),
          ).build(),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
