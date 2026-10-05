import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../core/weight/weight_unit_preference.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/weight_entry.dart';
import '../providers/weight_providers.dart';
import '../sheets/record_weight_sheet.dart';
import '../utils/weight_hub_labels.dart';
import 'weight_delete_dialog.dart';

class WeightHubHistoryList extends ConsumerWidget {
  const WeightHubHistoryList({
    required this.petId,
    required this.entries,
    super.key,
  });

  final String petId;
  final List<WeightEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitPreferenceProvider);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final displayWeight = formatWeight(entry.weight, unit);
        final dateLabel = DateFormat.yMMMd().format(
          calendarDateOnly(entry.date),
        );
        final fulfils = entry.fulfils;
        final chipLabel = fulfils != null
            ? l.weightCountsAs(fulfils.entryName)
            : (entry.measurementSource != 'guardian'
                  ? weightSourceChipLabel(l, entry.measurementSource)
                  : null);

        return ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: () =>
              showRecordWeightSheet(context, ref, petId: petId, editing: entry),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.monitor_weight,
              size: 20,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            displayWeight,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel + (entry.notes.isNotEmpty ? ' — ${entry.notes}' : ''),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (chipLabel != null) ...[
                const SizedBox(height: 4),
                Semantics(
                  label: fulfils != null
                      ? l.weightCountsAs(fulfils.entryName)
                      : chipLabel,
                  child: Chip(
                    label: Text(chipLabel),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.error,
              size: 20,
            ),
            tooltip: l.deleteWeightEntry,
            onPressed: () => confirmDeleteWeightEntry(
              context,
              ref,
              petId: petId,
              entry: entry,
            ),
          ),
        );
      },
    );
  }
}
