import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/widgets/health_entry_status.dart';
import '../../../../health_tracking/presentation/widgets/pet_event_lifecycle.dart';
import '../pet_care_section/pet_care_action_row_builder.dart';

/// Care items with no active temporal group (closed, completed, or outside horizon).
class AllCareInactiveSection extends StatelessWidget {
  const AllCareInactiveSection({
    super.key,
    required this.entries,
    required this.establishedEntryIds,
    required this.onViewEntry,
    required this.onMarkDone,
  });

  final List<HealthEntry> entries;
  final Set<String> establishedEntryIds;
  final void Function(HealthEntry entry) onViewEntry;
  final Future<void> Function(HealthEntry entry) onMarkDone;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      key: const Key('all_care_inactive_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              l.allCareInactiveSection,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _InactiveRow(
            entry: entries[i],
            l: l,
            colorScheme: colorScheme,
            isEstablished: establishedEntryIds.contains(entries[i].id),
            onViewEntry: onViewEntry,
            onMarkDone: onMarkDone,
          ),
        ],
      ],
    );
  }
}

class _InactiveRow extends StatelessWidget {
  const _InactiveRow({
    required this.entry,
    required this.l,
    required this.colorScheme,
    required this.isEstablished,
    required this.onViewEntry,
    required this.onMarkDone,
  });

  final HealthEntry entry;
  final AppLocalizations l;
  final ColorScheme colorScheme;
  final bool isEstablished;
  final void Function(HealthEntry entry) onViewEntry;
  final Future<void> Function(HealthEntry entry) onMarkDone;

  @override
  Widget build(BuildContext context) {
    final closed = isHealthEntrySeriesClosed(entry);

    return PetCareActionRowBuilder(
      entry: entry,
      l10n: l,
      colorScheme: colorScheme,
      isEstablished: isEstablished,
      trailingLabel: l.done,
      statusLineOverride: closed ? l.eventStatusClosed : null,
      statusTreatmentOverride: closed ? completedStatusTreatment() : null,
      onMarkDone: closed ? null : () => onMarkDone(entry),
      onTap: () => onViewEntry(entry),
    ).build();
  }
}

List<HealthEntry> sortInactiveAllCareEntries(List<HealthEntry> entries) {
  final sorted = [...entries];
  sorted.sort((a, b) {
    final aClosed = isHealthEntrySeriesClosed(a);
    final bClosed = isHealthEntrySeriesClosed(b);
    if (aClosed != bClosed) return aClosed ? 1 : -1;
    final ad = a.nextDueDate ?? a.startDate;
    final bd = b.nextDueDate ?? b.startDate;
    return bd.compareTo(ad);
  });
  return sorted;
}
