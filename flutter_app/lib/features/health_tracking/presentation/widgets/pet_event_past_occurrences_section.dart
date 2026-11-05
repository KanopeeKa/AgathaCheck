import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/shell_return_navigation.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_occurrence.dart';
import 'care_event_status_line.dart';
import 'pet_event_view_providers.dart';

/// Inline past occurrences (completed + skipped, newest first) for History.
class PetEventPastOccurrencesSection extends ConsumerWidget {
  const PetEventPastOccurrencesSection({
    super.key,
    required this.entryId,
    required this.muted,
    required this.maxVisibleRows,
    this.petId,
  });

  final String entryId;
  final bool muted;

  /// Inline row cap from the care item layout (3 mobile / 5 wide).
  final int maxVisibleRows;

  /// When set, each line opens its occurrence screen (§History, D-CIE-010).
  final String? petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pastAsync = ref.watch(entryPastOccurrencesProvider(entryId));

    return pastAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (past) {
        // Server returns completed + skipped only; guard unresolved overdue.
        final rows = past
            .where(
              (o) =>
                  o.status == 'completed' ||
                  o.status == 'skipped' ||
                  o.status == 'not_recorded',
            )
            .toList();
        if (rows.isEmpty) return const SizedBox.shrink();

        final visible = rows.take(maxVisibleRows).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final occ in visible)
                _PastOccurrenceCard(
                  occurrence: occ,
                  muted: muted,
                  petId: petId,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PastOccurrenceCard extends StatelessWidget {
  const _PastOccurrenceCard({
    required this.occurrence,
    required this.muted,
    this.petId,
  });

  final HealthOccurrence occurrence;
  final bool muted;
  final String? petId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();
    final scheduled = formatOccurrenceInstant(occurrence, l, context: context);

    final isNotRecorded =
        occurrence.status == 'not_recorded' ||
        occurrence.outcome == 'not_recorded';
    final statusLabel = isNotRecorded
        ? l.careStatusNotRecorded
        : occurrence.status == 'skipped'
        ? l.occurrenceSkipped
        : occurrence.completedOn != null
        ? l.doneOn(dateFormat.format(occurrence.completedOn!))
        : scheduled;

    final card = Card(
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
    final petId = this.petId;
    if (petId == null) return card;
    return InkWell(
      onTap: () => openOccurrenceScreen(
        context,
        petId: petId,
        entryId: occurrence.entryId,
        occurrenceId: occurrence.id,
      ),
      child: card,
    );
  }
}
