import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_history_entry.dart';
import '../providers/health_providers.dart';
import 'pet_event_lifecycle.dart';

/// Collapsible past iterations list with skip / unmark actions.
class PetEventPastIterationsSection extends ConsumerStatefulWidget {
  const PetEventPastIterationsSection({
    super.key,
    required this.entry,
    required this.history,
    required this.isClosed,
  });

  final HealthEntry entry;
  final List<HealthHistoryEntry> history;
  final bool isClosed;

  @override
  ConsumerState<PetEventPastIterationsSection> createState() =>
      _PetEventPastIterationsSectionState();
}

class _PetEventPastIterationsSectionState
    extends ConsumerState<PetEventPastIterationsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final past = pastIterationsForEntry(widget.entry, widget.history);
    if (past.isEmpty) return const SizedBox.shrink();

    final lastCompleted = lastCompletedHistory(widget.history);
    final dateFormat = DateFormat.yMMMd();
    final muted = widget.isClosed;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          ListTile(
            key: const Key('pet_event_past_iterations_header'),
            title: Text(l.pastIterations),
            trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  for (final row in past)
                    _PastIterationCard(
                      row: row,
                      dateFormat: dateFormat,
                      muted: muted,
                      canUnmark:
                          !muted &&
                          lastCompleted?.id == row.id &&
                          row.isCompleted,
                      canSkip: !muted && !row.isCompleted && !row.isSkipped,
                      onSkip: row.dueDate == null ? null : () => _skip(row),
                      onUnmark: () => _unmarkDone(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _skip(HealthHistoryEntry row) async {
    final dueDate = row.dueDate;
    if (dueDate == null) return;
    await ref
        .read(healthEntriesNotifierProvider.notifier)
        .skipIteration(widget.entry.id, dueDate: dueDate);
    ref.invalidate(entryHistoryProvider(widget.entry.id));
  }

  Future<void> _unmarkDone() async {
    await ref
        .read(healthEntriesNotifierProvider.notifier)
        .unmarkDone(widget.entry.id);
    ref.invalidate(entryHistoryProvider(widget.entry.id));
  }
}

class _PastIterationCard extends StatelessWidget {
  const _PastIterationCard({
    required this.row,
    required this.dateFormat,
    required this.muted,
    required this.canUnmark,
    required this.canSkip,
    required this.onUnmark,
    this.onSkip,
  });

  final HealthHistoryEntry row;
  final DateFormat dateFormat;
  final bool muted;
  final bool canUnmark;
  final bool canSkip;
  final VoidCallback? onSkip;
  final VoidCallback onUnmark;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = muted ? colorScheme.onSurfaceVariant : null;

    final dueLabel = row.dueDate != null
        ? dateFormat.format(row.dueDate!)
        : l.notSet;
    final statusLabel = row.isSkipped
        ? l.occurrenceSkipped
        : row.isCompleted && row.completedOn != null
        ? l.doneOn(dateFormat.format(row.completedOn!))
        : dueLabel;

    return Card(
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
              statusLabel,
              style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
            ),
            if (!muted && (canSkip || canUnmark)) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (canSkip && onSkip != null)
                    OutlinedButton(
                      key: Key('skip_iteration_${row.id}'),
                      onPressed: onSkip,
                      child: Text(l.skipOccurrence),
                    ),
                  if (canUnmark)
                    OutlinedButton(
                      key: Key('unmark_done_${row.id}'),
                      onPressed: onUnmark,
                      child: Text(l.unmarkDone),
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
