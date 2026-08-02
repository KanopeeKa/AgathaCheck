import 'package:flutter/material.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../core/utils/calendar_date_picker.dart';
import '../../../../l10n/app_localizations.dart';

class EntryDatePickerField extends StatelessWidget {
  const EntryDatePickerField({
    super.key,
    required this.label,
    required this.date,
    required this.onChanged,
    this.allowClear = false,
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;
  final bool allowClear;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final formatted =
        date != null ? formatCalendarDateDisplay(date!) : l.notSet;
    return Semantics(
      label: '$label: $formatted',
      button: true,
      hint: l.tapToChangeDate,
      child: InkWell(
        onTap: () async {
          final picked = await showCalendarDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: firstDate ?? DateTime(2020),
            lastDate: lastDate ?? DateTime(2100),
          );
          if (picked != null) {
            onChanged(picked);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: allowClear && date != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => onChanged(null),
                    tooltip: l.clear,
                  )
                : null,
          ),
          child: Text(
            formatted,
            style: date == null
                ? TextStyle(color: Theme.of(context).hintColor)
                : null,
          ),
        ),
      ),
    );
  }
}
