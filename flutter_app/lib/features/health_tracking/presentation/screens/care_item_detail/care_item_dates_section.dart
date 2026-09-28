import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_item_module.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_item_section_header.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_item_status_pill.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_surface_tokens.dart';
import '../../../domain/entities/health_entry.dart';
import '../../../domain/entities/health_occurrence.dart';
import '../../../domain/occurrence_scheduling.dart';
import '../../providers/occurrence_providers.dart';
import '../../widgets/care_event_status_line.dart';
import '../../widgets/pet_event_occurrence_actions.dart';

/// Upcoming and recent dates for a care item (spec §4.3 — **Needs attention** module).
class CareItemDatesSection extends ConsumerWidget {
  const CareItemDatesSection({
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
    final occurrencesAsync = ref.watch(entryOccurrencesProvider(entry.id));
    final summary = ref.watch(occurrenceSummaryProvider(entry.id));

    return occurrencesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _LegacyDatesSummary(entry: entry, muted: muted),
      data: (occurrences) {
        if (entry.isPaused) {
          return CareItemModule(
            key: const Key('care_item_needs_attention_section'),
            semanticLabel: l.careItemNeedsAttentionTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CareItemSectionHeader(
                  title: l.careItemNeedsAttentionTitle,
                  icon: Icons.flag_outlined,
                ),
                const SizedBox(height: 12),
                _PausedAttentionBanner(entry: entry, muted: muted),
              ],
            ),
          );
        }

        if (occurrences.isEmpty) {
          return _LegacyDatesSummary(entry: entry, muted: muted);
        }

        final now = DateTime.now();
        final missed = _zoneItems(occurrences, OccurrenceZone.missed, now);
        final dueToday = _zoneItems(occurrences, OccurrenceZone.dueToday, now);
        final comingUp = _zoneItems(occurrences, OccurrenceZone.comingUp, now);

        return CareItemModule(
          key: const Key('care_item_needs_attention_section'),
          semanticLabel: l.careItemNeedsAttentionTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CareItemSectionHeader(
                title: l.careItemNeedsAttentionTitle,
                icon: Icons.flag_outlined,
              ),
              const SizedBox(height: 12),
              if (missed.isNotEmpty)
                _OccurrenceZoneBlock(
                  zone: OccurrenceZone.missed,
                  occurrences: missed,
                  entry: entry,
                  muted: muted,
                ),
              if (dueToday.isNotEmpty)
                _OccurrenceZoneBlock(
                  zone: OccurrenceZone.dueToday,
                  occurrences: dueToday,
                  entry: entry,
                  muted: muted,
                ),
              if (comingUp.isNotEmpty)
                _OccurrenceZoneBlock(
                  zone: OccurrenceZone.comingUp,
                  occurrences: comingUp,
                  entry: entry,
                  muted: muted,
                ),
              if (!muted && summary.missedCount > 0) ...[
                const SizedBox(height: 4),
                OutlinedButton(
                  key: const Key('care_item_skip_all_missed'),
                  onPressed: () => PetEventOccurrenceActions.skipAllMissed(
                    context,
                    ref,
                    entry,
                  ),
                  child: Text(l.occurrenceSkipAllMissed),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

CareItemStatusTone _statusToneForZone(OccurrenceZone zone) {
  return switch (zone) {
    OccurrenceZone.missed => CareItemStatusTone.overdue,
    OccurrenceZone.dueToday => CareItemStatusTone.due,
    OccurrenceZone.comingUp => CareItemStatusTone.neutral,
  };
}

String _pillLabelForZone(OccurrenceZone zone, AppLocalizations l) {
  return switch (zone) {
    OccurrenceZone.missed => l.occurrenceZoneMissed,
    OccurrenceZone.dueToday => l.occurrenceZoneDueToday,
    OccurrenceZone.comingUp => l.occurrenceZoneComingUp,
  };
}

class _OccurrenceZoneBlock extends StatelessWidget {
  const _OccurrenceZoneBlock({
    required this.zone,
    required this.occurrences,
    required this.entry,
    required this.muted,
  });

  final OccurrenceZone zone;
  final List<HealthOccurrence> occurrences;
  final HealthEntry entry;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pillLabel = _pillLabelForZone(zone, l);
    final tone = _statusToneForZone(zone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final occ in occurrences)
          _OccurrenceRow(
            occurrence: occ,
            entry: entry,
            muted: muted,
            pillLabel: pillLabel,
            statusTone: tone,
          ),
      ],
    );
  }
}

class _OccurrenceRow extends ConsumerWidget {
  const _OccurrenceRow({
    required this.occurrence,
    required this.entry,
    required this.muted,
    required this.pillLabel,
    required this.statusTone,
  });

  final HealthOccurrence occurrence;
  final HealthEntry entry;
  final bool muted;
  final String pillLabel;
  final CareItemStatusTone statusTone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateLabel = formatOccurrenceInstant(occurrence, l, context: context);

    return Container(
      key: Key('care_item_occurrence_row_${occurrence.id}'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CareSurfaceTokens.actionRadius),
        border: Border.all(color: CareSurfaceTokens.moduleBorder()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CareItemStatusPill(label: pillLabel, tone: statusTone),
          const SizedBox(height: 10),
          Text(
            dateLabel,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: muted
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (!muted) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: Key('care_item_occurrence_mark_done_${occurrence.id}'),
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
                  key: Key('care_item_occurrence_skip_${occurrence.id}'),
                  onPressed: () => PetEventOccurrenceActions.skip(
                    context,
                    ref,
                    entry,
                    occurrence,
                  ),
                  child: Text(l.skipOccurrence),
                ),
                OutlinedButton(
                  key: Key('care_item_occurrence_reschedule_${occurrence.id}'),
                  onPressed: () => PetEventOccurrenceActions.changeDate(
                    context,
                    ref,
                    entry,
                    occurrence,
                  ),
                  child: Text(l.rescheduleActionLabel),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LegacyDatesSummary extends StatelessWidget {
  const _LegacyDatesSummary({required this.entry, required this.muted});

  final HealthEntry entry;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = formatCareEventStatusLine(entry, l, colorScheme);

    return Column(
      key: const Key('care_item_dates_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l.careItemDatesTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: muted ? colorScheme.onSurfaceVariant : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          key: Key('care_item_dates_summary_${entry.id}'),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: CareEventStatusLineView(
            status: status,
            theme: theme,
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }
}

class _PausedAttentionBanner extends StatelessWidget {
  const _PausedAttentionBanner({required this.entry, required this.muted});

  final HealthEntry entry;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final since = entry.pausedSince;
    final line = since != null
        ? l.careItemPausedSince(DateFormat.yMMMd().format(since))
        : l.careItemPausedStatus;

    return Container(
      key: const Key('care_item_paused_banner'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CareSurfaceTokens.actionRadius),
        border: Border.all(color: CareSurfaceTokens.moduleBorder()),
      ),
      child: Text(
        line,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: muted ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
