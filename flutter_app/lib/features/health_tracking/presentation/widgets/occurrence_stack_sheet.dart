import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_occurrence.dart';
import '../../domain/occurrence_scheduling.dart';
import 'care_event_status_line.dart';
import 'mark_complete_sheet.dart';

/// Result of a list-row mark-done flow (optimistic parents persist after return).
class OccurrenceMarkDoneResult {
  const OccurrenceMarkDoneResult({
    required this.completedOn,
    this.occurrenceId,
    this.skipEarlierMissed = false,
    this.alreadyPersisted = false,
  });

  final DateTime completedOn;
  final String? occurrenceId;
  final bool skipEarlierMissed;
  final bool alreadyPersisted;
}

/// Shows the occurrence triage bottom sheet for a care series.
///
/// Returns an [OccurrenceMarkDoneResult] when the user records the head dose;
/// null when dismissed or when skip-all-missed already persisted server-side.
Future<OccurrenceMarkDoneResult?> showOccurrenceStackSheet(
  BuildContext context, {
  required HealthEntry entry,
  required List<HealthOccurrence> occurrences,
  required Future<void> Function(
    String occurrenceId,
    DateTime completedOn,
    bool skipEarlierMissed,
  )
  onRecordHead,
  required Future<void> Function() onSkipAllMissed,
}) {
  return showModalBottomSheet<OccurrenceMarkDoneResult>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => OccurrenceStackSheet(
      entry: entry,
      occurrences: occurrences,
      onRecordHead: onRecordHead,
      onSkipAllMissed: onSkipAllMissed,
    ),
  );
}

/// Bottom sheet listing missed / due today / coming up zones for triage.
class OccurrenceStackSheet extends StatefulWidget {
  const OccurrenceStackSheet({
    super.key,
    required this.entry,
    required this.occurrences,
    required this.onRecordHead,
    required this.onSkipAllMissed,
  });

  final HealthEntry entry;
  final List<HealthOccurrence> occurrences;
  final Future<void> Function(
    String occurrenceId,
    DateTime completedOn,
    bool skipEarlierMissed,
  )
  onRecordHead;
  final Future<void> Function() onSkipAllMissed;

  @override
  State<OccurrenceStackSheet> createState() => _OccurrenceStackSheetState();
}

class _OccurrenceStackSheetState extends State<OccurrenceStackSheet> {
  bool _skipEarlierMissed = false;
  bool _busy = false;

  OccurrenceSummary get _summary =>
      summarizeOpenOccurrences(widget.occurrences, DateTime.now());

  HealthOccurrence? get _headOccurrence {
    final summary = _summary;
    if (summary.missedCount > 0) return summary.missedHead;
    return summary.nextHead;
  }

  List<HealthOccurrence> _zoneItems(OccurrenceZone zone, DateTime now) {
    final bucket = widget.occurrences
        .where((o) => occurrenceZone(o, now) == zone)
        .toList();
    return sortOccurrencesByZone(bucket, zone);
  }

  Future<void> _handleRecordHead() async {
    final head = _headOccurrence;
    if (head == null || _busy) return;

    final completedOn = await showMarkCompleteSheet(context);
    if (completedOn == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await widget.onRecordHead(
        head.id,
        completedOn,
        _skipEarlierMissed && _summary.missedCount > 1,
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        OccurrenceMarkDoneResult(
          completedOn: completedOn,
          occurrenceId: head.id,
          skipEarlierMissed: _skipEarlierMissed && _summary.missedCount > 1,
          alreadyPersisted: true,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skipAllMissed() async {
    if (_summary.missedCount == 0 || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.onSkipAllMissed();
      if (!mounted) return;
      Navigator.pop(
        context,
        OccurrenceMarkDoneResult(
          completedOn: DateTime.now(),
          alreadyPersisted: true,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reviewEntry() {
    final petId = widget.entry.petId;
    if (petId.isEmpty) return;
    Navigator.pop(context);
    context.push('/pet/$petId/events/${widget.entry.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final summary = _summary;
    final missed = _zoneItems(OccurrenceZone.missed, now);
    final dueToday = _zoneItems(OccurrenceZone.dueToday, now);
    final comingUp = _zoneItems(OccurrenceZone.comingUp, now);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.occurrenceStackSheetTitle(widget.entry.name),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (missed.isNotEmpty)
            _OccurrenceZoneSection(
              title: l.occurrenceZoneMissed,
              occurrences: missed,
              titleColor: theme.colorScheme.error,
            ),
          if (dueToday.isNotEmpty)
            _OccurrenceZoneSection(
              title: l.occurrenceZoneDueToday,
              occurrences: dueToday,
            ),
          if (comingUp.isNotEmpty)
            _OccurrenceZoneSection(
              title: l.occurrenceZoneComingUp,
              occurrences: comingUp,
            ),
          if (summary.missedCount > 1)
            CheckboxListTile(
              key: const Key('occurrence_skip_earlier_missed'),
              contentPadding: EdgeInsets.zero,
              title: Text(l.occurrenceSkipEarlierMissed),
              value: _skipEarlierMissed,
              onChanged: _busy
                  ? null
                  : (value) =>
                        setState(() => _skipEarlierMissed = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('occurrence_record_head'),
            onPressed: _busy || _headOccurrence == null
                ? null
                : _handleRecordHead,
            child: Text(l.occurrenceRecordHead),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('occurrence_review_entry'),
            onPressed: _busy ? null : _reviewEntry,
            child: Text(l.occurrenceReviewEach),
          ),
          if (summary.missedCount > 0) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('occurrence_skip_all_missed'),
              onPressed: _busy ? null : _skipAllMissed,
              child: Text(l.occurrenceSkipAllMissed),
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            key: const Key('occurrence_not_now'),
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(l.occurrenceNotNow),
          ),
        ],
      ),
    );
  }
}

class _OccurrenceZoneSection extends StatelessWidget {
  const _OccurrenceZoneSection({
    required this.title,
    required this.occurrences,
    this.titleColor,
  });

  final String title;
  final List<HealthOccurrence> occurrences;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
          ...occurrences.map(
            (occ) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                formatOccurrenceInstant(occ, l, context: context),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
