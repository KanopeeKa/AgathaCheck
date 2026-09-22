import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'entry_date_picker_field.dart';

/// Side-by-side due date and completed-on pickers (at least one required).
class EntryDueCompletedRow extends StatelessWidget {
  const EntryDueCompletedRow({
    super.key,
    required this.dueDate,
    required this.completedOn,
    required this.onDueDateChanged,
    required this.onCompletedOnChanged,
    this.dueLabel,
    this.completedLabel,
    this.showDueDate = true,
    this.requireCompletedOn = false,
  });

  final DateTime? dueDate;
  final DateTime? completedOn;
  final ValueChanged<DateTime?> onDueDateChanged;
  final ValueChanged<DateTime?> onCompletedOnChanged;
  final String? dueLabel;
  final String? completedLabel;
  final bool showDueDate;
  final bool requireCompletedOn;

  String? _validate(AppLocalizations l) {
    if (requireCompletedOn && completedOn == null) {
      return l.completedOnRequired;
    }
    if (showDueDate && dueDate == null && completedOn == null) {
      return l.dueOrCompletedRequired;
    }
    if (!showDueDate && completedOn == null) {
      return l.completedOnRequired;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final error = _validate(l);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDueDate) ...[
              Expanded(
                child: EntryDatePickerField(
                  label: dueLabel ?? l.dueDate,
                  date: dueDate,
                  onChanged: onDueDateChanged,
                  allowClear: true,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: EntryDatePickerField(
                label: completedLabel ?? l.completedOn,
                date: completedOn,
                onChanged: onCompletedOnChanged,
                allowClear: !requireCompletedOn,
              ),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              error,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
