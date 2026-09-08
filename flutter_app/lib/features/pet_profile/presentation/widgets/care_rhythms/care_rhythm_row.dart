import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/widgets/health_entry_status.dart';
import '../../../../health_tracking/presentation/widgets/pet_event_lifecycle.dart';
import '../../../../../l10n/app_localizations.dart';
import '../care_family_icon.dart';
import '../care_source_labels.dart';

/// One recurring-care rhythm row: family icon, cadence, next due, provenance.
class CareRhythmRow extends StatelessWidget {
  const CareRhythmRow({super.key, required this.entry, required this.petId});

  final HealthEntry entry;
  final String petId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final closed = isHealthEntrySeriesClosed(entry);
    final cadence = formatRecurrenceSummary(l, entry);
    final provenance = careSourceLabel(l, entry.careSource);
    final nextDue = _nextDueLine(l, entry, closed);

    return ListTile(
      key: Key('care_rhythm_row_${entry.id}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CareFamilyIcon.forEntry(entry),
      title: Text(entry.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cadence),
          if (nextDue != null)
            Text(
              nextDue,
              style: theme.textTheme.bodySmall?.copyWith(
                color: closed
                    ? colorScheme.onSurfaceVariant
                    : healthEntryStatusColor(entry, colorScheme),
              ),
            ),
          if (provenance != null)
            Text(
              provenance,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/pet/$petId/events/${entry.id}'),
    );
  }

  String? _nextDueLine(AppLocalizations l, HealthEntry entry, bool closed) {
    if (closed) return l.eventStatusClosed;
    if (entry.nextDueDate == null) return l.notSet;
    return l.careRhythmNextDue(formatHealthEntryStatusDate(entry.nextDueDate!));
  }
}
