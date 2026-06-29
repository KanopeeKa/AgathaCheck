import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'entry_form_labels.dart';

class EntryDatePickerField extends StatelessWidget {
  const EntryDatePickerField({
    super.key,
    required this.label,
    required this.date,
    required this.onChanged,
    this.allowClear = false,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final formatted = date != null ? formatEntryDate(date!) : l.notSet;
    return Semantics(
      label: '$label: $formatted',
      button: true,
      hint: l.tapToChangeDate,
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            onChanged(DateTime(picked.year, picked.month, picked.day));
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
