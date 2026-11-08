import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/utils/care_instant_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_occurrence.dart';
import 'health_entry_status.dart';
import 'past_occurrence_history_utils.dart';

/// One-line History pill (inline module + full-history pop-up).
class PastOccurrenceHistoryPill extends StatelessWidget {
  const PastOccurrenceHistoryPill({
    super.key,
    required this.occurrence,
    required this.muted,
    this.onTap,
  });

  final HealthOccurrence occurrence;
  final bool muted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dueLine = formatCareDueInstant(
      scheduledDate: occurrence.scheduledDate,
      scheduledTime: occurrence.scheduledTime,
      dateOnly: (d) => d,
      dateAtTime: (d, t) => l.occurrenceDateAtTime(d, t),
    );

    final isNotRecorded = occurrenceIsNotRecorded(occurrence);
    final isSkipped = occurrenceIsSkipped(occurrence);
    final isDone = occurrenceIsDone(occurrence);

    final IconData icon;
    final Color iconColor;
    String? closeDate;
    String semanticsLabel;

    if (isNotRecorded) {
      icon = Icons.help_outline;
      iconColor = colorScheme.onSurfaceVariant;
      semanticsLabel = l.historyPillA11yNotRecorded(dueLine);
    } else if (isSkipped) {
      icon = Icons.skip_next;
      iconColor = colorScheme.onSurfaceVariant;
      final recorded = occurrence.markedAt;
      closeDate = recorded != null
          ? formatCareRecordedCalendarDate(
              recorded.isUtc ? recorded.toLocal() : recorded,
            )
          : (occurrence.completedOn != null
                ? formatHealthEntryStatusDate(occurrence.completedOn!)
                : null);
      semanticsLabel = closeDate != null
          ? l.historyPillA11ySkipped(dueLine, closeDate)
          : l.historyPillA11yNotRecorded(dueLine);
    } else if (isDone) {
      icon = Icons.check_circle;
      iconColor = AppColorTokens.success;
      closeDate = occurrence.completedOn != null
          ? formatHealthEntryStatusDate(occurrence.completedOn!)
          : null;
      semanticsLabel = closeDate != null
          ? l.historyPillA11yDone(dueLine, closeDate)
          : dueLine;
    } else {
      icon = Icons.help_outline;
      iconColor = colorScheme.onSurfaceVariant;
      semanticsLabel = dueLine;
    }

    final line = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            dueLine,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: muted ? colorScheme.onSurfaceVariant : null,
            ),
          ),
        ),
        Text(
          ' – ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Icon(icon, size: 18, color: iconColor),
        if (closeDate != null)
          Text(
            ' $closeDate',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: muted ? colorScheme.onSurfaceVariant : null,
            ),
          ),
      ],
    );

    final card = Card(
      key: Key('pet_event_past_occurrence_${occurrence.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(
        alpha: muted ? 0.5 : 1,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: onTap != null ? 48 : 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Align(alignment: Alignment.centerLeft, child: line),
        ),
      ),
    );

    final body = Semantics(
      container: true,
      button: onTap != null,
      label: semanticsLabel,
      excludeSemantics: true,
      child: card,
    );

    if (onTap == null) return body;
    return InkWell(onTap: onTap, child: body);
  }
}
