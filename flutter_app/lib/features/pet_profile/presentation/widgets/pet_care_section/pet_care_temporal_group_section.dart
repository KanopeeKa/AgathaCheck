import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../pet_care/domain/care_temporal_group.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_collection_inset_list.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_surface_tokens.dart';
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
    this.inset = false,
  });

  final CareTemporalGroup group;
  final List<HealthEntry> entries;
  final Set<String> establishedEntryIds;
  final String trailingLabel;
  final void Function(HealthEntry entry) onMarkDone;
  final void Function(HealthEntry entry) onViewEntry;
  final bool inset;

  static List<CareCollectionInsetItem> buildInsetItems({
    required BuildContext context,
    required List<CareTemporalGroup> groups,
    required Map<CareTemporalGroup, List<HealthEntry>> buckets,
    required Set<String> establishedEntryIds,
    required String trailingLabel,
    required void Function(HealthEntry entry) onMarkDone,
    required void Function(HealthEntry entry) onViewEntry,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final items = <CareCollectionInsetItem>[];

    for (final group in groups) {
      final entries = buckets[group] ?? const <HealthEntry>[];
      if (entries.isEmpty) continue;

      final groupLabel = petCareTemporalGroupLabel(l10n, group);
      final groupIcon = petCareTemporalGroupIcon(group);

      if (items.isNotEmpty) {
        items.add(
          CareCollectionInsetItem(
            showDividerBefore: true,
            child: _InsetGroupHeader(
              key: Key('pet_care_group_${group.name}'),
              groupLabel: groupLabel,
              groupIcon: groupIcon,
              colorScheme: colorScheme,
            ),
          ),
        );
      } else {
        items.add(
          CareCollectionInsetItem(
            child: _InsetGroupHeader(
              key: Key('pet_care_group_${group.name}'),
              groupLabel: groupLabel,
              groupIcon: groupIcon,
              colorScheme: colorScheme,
            ),
          ),
        );
      }

      for (var i = 0; i < entries.length; i++) {
        items.add(
          CareCollectionInsetItem(
            showDividerBefore: true,
            child: PetCareActionRowBuilder(
              entry: entries[i],
              l10n: l10n,
              colorScheme: colorScheme,
              isEstablished: establishedEntryIds.contains(entries[i].id),
              trailingLabel: trailingLabel,
              onMarkDone: () => onMarkDone(entries[i]),
              onTap: () => onViewEntry(entries[i]),
            ).build(inset: true),
          ),
        );
      }
    }

    return items;
  }

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
          ).build(inset: inset),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _InsetGroupHeader extends StatelessWidget {
  const _InsetGroupHeader({
    super.key,
    required this.groupLabel,
    required this.groupIcon,
    required this.colorScheme,
  });

  final String groupLabel;
  final IconData groupIcon;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: groupLabel,
      child: Padding(
        padding: CareSurfaceTokens.collectionHeaderPadding,
        child: Row(
          children: [
            Icon(groupIcon, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              groupLabel,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
