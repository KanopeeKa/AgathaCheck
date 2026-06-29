import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'entry_form_labels.dart';

class EntryDatePickerField extends StatelessWidget {
  const EntryDatePickerField({
    super.key,
    required this.label,
    required this.date,
    required this.onChanged,
  });

  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final formatted = formatEntryDate(date);
    return Semantics(
      label: '$label: $formatted',
      button: true,
      hint: l.tapToChangeDate,
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked != null) {
            onChanged(DateTime(
              picked.year,
              picked.month,
              picked.day,
              date.hour,
              date.minute,
            ));
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Text(formatted),
        ),
      ),
    );
  }
}
