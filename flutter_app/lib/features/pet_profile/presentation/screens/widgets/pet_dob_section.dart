import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/utils/calendar_date.dart';
import '../../../../../core/utils/calendar_date_picker.dart';

class PetDobSection extends StatelessWidget {
  final DateTime? dateOfBirth;
  final ValueChanged<DateTime?> onChanged;

  const PetDobSection({
    super.key,
    required this.dateOfBirth,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      label: l.dateOfBirth,
      child: InkWell(
        key: const Key('pet_dob_field'),
        onTap: () async {
          final picked = await showCalendarDatePicker(
            context: context,
            initialDate: dateOfBirth ?? DateTime.now(),
            firstDate: DateTime(1980),
            lastDate: DateTime.now(),
            helpText: 'Select date of birth',
          );
          if (picked != null) {
            onChanged(picked);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: l.dateOfBirth,
            helperText: 'Used to calculate your pet\'s age',
            suffixIcon: dateOfBirth != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    tooltip: 'Clear date of birth',
                    onPressed: () => onChanged(null),
                  )
                : const Icon(Icons.calendar_today, size: 18),
          ),
          child: Text(
            dateOfBirth != null ? formatCalendarDateDisplay(dateOfBirth!) : '',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
