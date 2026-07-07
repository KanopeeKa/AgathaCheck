import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recurrence_anchor.dart';

/// Toggle for how the next recurring occurrence is scheduled.
class RecurrenceAnchorToggle extends StatelessWidget {
  const RecurrenceAnchorToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final RecurrenceAnchor value;
  final ValueChanged<RecurrenceAnchor> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.recurrenceAnchorTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<RecurrenceAnchor>(
          segments: [
            ButtonSegment(
              value: RecurrenceAnchor.fromCompletion,
              label: Text(
                l.recurrenceFromCompletion,
                textAlign: TextAlign.center,
              ),
            ),
            ButtonSegment(
              value: RecurrenceAnchor.fromDueDate,
              label: Text(l.recurrenceFromDueDate, textAlign: TextAlign.center),
            ),
          ],
          selected: {value},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
        const SizedBox(height: 8),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: Text(
            l.recurrenceAnchorInfoTitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          children: [
            Text(l.recurrenceAnchorInfoBody, style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
