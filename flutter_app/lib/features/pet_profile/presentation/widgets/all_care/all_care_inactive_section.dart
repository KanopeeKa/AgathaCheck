import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/widgets/pet_event_lifecycle.dart';
import '../pet_care_section/pet_care_action_row_builder.dart';

/// Care items with no active temporal group (closed, completed, or outside horizon).
class AllCareInactiveSection extends StatelessWidget {
  const AllCareInactiveSection({
    super.key,
    required this.entries,
    required this.establishedEntryIds,
    required this.onViewEntry,
  });

  final List<HealthEntry> entries;
  final Set<String> establishedEntryIds;
  final void Function(HealthEntry entry) onViewEntry;

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
              l.eventFilterClosed,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          PetCareActionRowBuilder(
            entry: entries[i],
            l10n: l,
            colorScheme: colorScheme,
            isEstablished: establishedEntryIds.contains(entries[i].id),
            trailingLabel: l.done,
            onTap: () => onViewEntry(entries[i]),
          ).build(),
        ],
      ],
    );
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
