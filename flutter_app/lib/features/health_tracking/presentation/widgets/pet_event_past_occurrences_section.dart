import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_occurrence.dart';
import 'care_event_status_line.dart';
import 'pet_event_view_providers.dart';

/// Collapsible past occurrences (completed + skipped, LIFO).
class PetEventPastOccurrencesSection extends ConsumerStatefulWidget {
  const PetEventPastOccurrencesSection({
    super.key,
    required this.entryId,
    required this.muted,
  });

  final String entryId;
  final bool muted;

  @override
  ConsumerState<PetEventPastOccurrencesSection> createState() =>
      _PetEventPastOccurrencesSectionState();
}

class _PetEventPastOccurrencesSectionState
    extends ConsumerState<PetEventPastOccurrencesSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final pastAsync = ref.watch(entryPastOccurrencesProvider(widget.entryId));

    return pastAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (past) {
        if (past.isEmpty) return const SizedBox.shrink();

        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          child: Column(
            children: [
              ListTile(
                key: const Key('pet_event_past_occurrences_header'),
                title: Text(l.pastIterations),
                trailing: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                ),
                onTap: () => setState(() => _expanded = !_expanded),
              ),
              if (_expanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: [
                      for (final occ in past)
                        _PastOccurrenceCard(
                          occurrence: occ,
                          muted: widget.muted,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PastOccurrenceCard extends StatelessWidget {
  const _PastOccurrenceCard({required this.occurrence, required this.muted});

  final HealthOccurrence occurrence;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();
    final scheduled = formatOccurrenceInstant(occurrence, l, context: context);

    final statusLabel = occurrence.status == 'skipped'
        ? l.occurrenceSkipped
        : occurrence.completedOn != null
        ? l.doneOn(dateFormat.format(occurrence.completedOn!))
        : scheduled;

    return Card(
      key: Key('pet_event_past_occurrence_${occurrence.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(
        alpha: muted ? 0.5 : 1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              scheduled,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              statusLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: muted ? colorScheme.onSurfaceVariant : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
