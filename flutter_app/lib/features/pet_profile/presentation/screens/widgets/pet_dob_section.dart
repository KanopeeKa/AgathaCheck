import 'package:flutter/material.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../core/utils/calendar_date_picker.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../widgets/pet_form/pet_form_labeled_field.dart';

class PetDobSection extends StatelessWidget {
  const PetDobSection({
    super.key,
    required this.dateOfBirth,
    required this.onChanged,
  });

  final DateTime? dateOfBirth;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return PetFormLabeledField(
      label: l.dateOfBirth,
      child: Semantics(
        label: l.dateOfBirth,
        child: InkWell(
          key: const Key('pet_dob_field'),
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final picked = await showCalendarDatePicker(
              context: context,
              initialDate: dateOfBirth ?? DateTime.now(),
              firstDate: DateTime(1980),
              lastDate: DateTime.now(),
              helpText: l.dateOfBirth,
            );
            if (picked != null) onChanged(picked);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              suffixIcon: dateOfBirth != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: l.clearDate,
                      onPressed: () => onChanged(null),
                    )
                  : const Icon(Icons.calendar_today, size: 18),
            ),
            child: Text(
              dateOfBirth != null
                  ? formatCalendarDateMedium(dateOfBirth!)
                  : l.selectDate,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: dateOfBirth != null
                    ? null
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
