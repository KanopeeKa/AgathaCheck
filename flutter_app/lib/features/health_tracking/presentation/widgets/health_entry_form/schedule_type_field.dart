import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/recurrence_anchor.dart';

/// Schedule type control (D-CSM-020, F35): Fixed schedule vs After it's done.
class ScheduleTypeField extends StatelessWidget {
  const ScheduleTypeField({
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
        Semantics(
          label: l.recurrenceAnchorTitle,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l.recurrenceAnchorTitle,
              border: const OutlineInputBorder(),
            ),
            child: SegmentedButton<RecurrenceAnchor>(
              key: const Key('care_schedule_type'),
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
                  label: Text(
                    l.recurrenceFromDueDate,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              selected: {value},
              onSelectionChanged: (s) => onChanged(s.first),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ExpansionTile(
          key: const Key('care_schedule_type_info'),
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
