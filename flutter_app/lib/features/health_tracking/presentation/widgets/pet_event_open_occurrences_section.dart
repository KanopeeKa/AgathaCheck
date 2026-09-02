import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_occurrence.dart';
import '../../domain/occurrence_scheduling.dart';
import '../providers/occurrence_providers.dart';
import 'care_event_status_line.dart';
import 'pet_event_occurrence_actions.dart';

/// Zoned open-occurrence workbench for [PetEventViewBody].
class PetEventOpenOccurrencesSection extends ConsumerWidget {
  const PetEventOpenOccurrencesSection({
    super.key,
    required this.entry,
    required this.muted,
  });

  final HealthEntry entry;
  final bool muted;

  List<HealthOccurrence> _zoneItems(
    List<HealthOccurrence> occurrences,
    OccurrenceZone zone,
    DateTime now,
  ) {
    final bucket = occurrences
        .where((o) => occurrenceZone(o, now) == zone)
        .toList();
    return sortOccurrencesByZone(bucket, zone);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final occurrencesAsync = ref.watch(entryOccurrencesProvider(entry.id));
    final summary = ref.watch(occurrenceSummaryProvider(entry.id));

    return occurrencesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _LegacySummary(entry: entry, muted: muted),
      data: (occurrences) {
        if (occurrences.isEmpty) {
          return _LegacySummary(entry: entry, muted: muted);
        }

        final now = DateTime.now();
        final missed = _zoneItems(occurrences, OccurrenceZone.missed, now);
        final dueToday = _zoneItems(occurrences, OccurrenceZone.dueToday, now);
        final comingUp = _zoneItems(occurrences, OccurrenceZone.comingUp, now);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.nextOccurrence,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: muted ? colorScheme.onSurfaceVariant : null,
              ),
            ),
            const SizedBox(height: 8),
            if (missed.isNotEmpty)
              _OccurrenceZoneBlock(
                title: l.occurrenceZoneMissed,
                titleColor: colorScheme.error,
                occurrences: missed,
                entry: entry,
                muted: muted,
              ),
            if (dueToday.isNotEmpty)
              _OccurrenceZoneBlock(
                title: l.occurrenceZoneDueToday,
                occurrences: dueToday,
                entry: entry,
                muted: muted,
              ),
            if (comingUp.isNotEmpty)
              _OccurrenceZoneBlock(
                title: l.occurrenceZoneComingUp,
                occurrences: comingUp,
                entry: entry,
                muted: muted,
              ),
            if (!muted && summary.missedCount > 0) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('pet_event_skip_all_missed'),
                onPressed: () =>
                    PetEventOccurrenceActions.skipAllMissed(context, ref, entry),
                child: Text(l.occurrenceSkipAllMissed),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _OccurrenceZoneBlock extends StatelessWidget {
  const _OccurrenceZoneBlock({
    required this.title,
    required this.occurrences,
    required this.entry,
    required this.muted,
    this.titleColor,
  });

  final String title;
  final List<HealthOccurrence> occurrences;
  final HealthEntry entry;
  final bool muted;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: titleColor ?? theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          for (final occ in occurrences)
            _OccurrenceRow(
              occurrence: occ,
              entry: entry,
              muted: muted,
            ),
        ],
      ),
    );
  }
}

class _OccurrenceRow extends ConsumerWidget {
  const _OccurrenceRow({
    required this.occurrence,
    required this.entry,
    required this.muted,
  });

  final HealthOccurrence occurrence;
  final HealthEntry entry;
  final bool muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final label = formatOccurrenceInstant(occurrence, l, context: context);

    return Card(
      key: Key('pet_event_occurrence_row_${occurrence.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(
        alpha: muted ? 0.5 : 0.35,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: muted ? colorScheme.onSurfaceVariant : null,
              ),
            ),
            if (!muted) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    key: Key('pet_event_occurrence_mark_done_${occurrence.id}'),
                    onPressed: () => PetEventOccurrenceActions.markDone(
                      context,
                      ref,
                      entry,
                      occurrence,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(l.markAsDone),
                  ),
                  OutlinedButton(
                    key: Key('pet_event_occurrence_skip_${occurrence.id}'),
                    onPressed: () => PetEventOccurrenceActions.skip(
                      context,
                      ref,
                      entry,
                      occurrence,
                    ),
                    child: Text(l.skipOccurrence),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegacySummary extends StatelessWidget {
  const _LegacySummary({required this.entry, required this.muted});

  final HealthEntry entry;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = formatCareEventStatusLine(entry, l, colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.nextOccurrence,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: muted ? colorScheme.onSurfaceVariant : null,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          key: Key('pet_event_occurrence_summary_${entry.id}'),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Text(
            status.text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: status.statusColor ?? colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
