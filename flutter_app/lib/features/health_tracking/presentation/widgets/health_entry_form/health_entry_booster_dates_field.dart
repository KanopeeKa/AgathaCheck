import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../core/utils/calendar_date_picker.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../controllers/health_entry_form_controller.dart';
import '../../controllers/health_entry_form_state.dart';

/// Vaccination booster dates at create (UIR-15, D-CSM-025).
class HealthEntryBoosterDatesField extends ConsumerWidget {
  const HealthEntryBoosterDatesField({
    super.key,
    required this.params,
    required this.form,
  });

  final HealthEntryFormParams params;
  final HealthEntryFormState form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final notifier = ref.read(
      healthEntryFormControllerProvider(params).notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final date in form.boosterPlannedDates)
          Semantics(
            identifier:
                'health_entry_booster_chip_${toCalendarDateString(date)}',
            label: l.careRemoveBoosterDate(DateFormat.MMMd().format(date)),
            child: InputChip(
              key: Key('health_entry_booster_${toCalendarDateString(date)}'),
              label: Text(DateFormat.yMMMd().format(date)),
              deleteIcon: const Icon(Icons.close),
              onDeleted: () => notifier.removeBoosterDate(date),
              deleteButtonTooltipMessage: l.careRemoveBoosterDate(
                DateFormat.MMMd().format(date),
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('health_entry_add_booster_date'),
            onPressed: () async {
              final today = calendarDateOnly(DateTime.now());
              final first = form.dueDate ?? today;
              final picked = await showCalendarDatePicker(
                context: context,
                initialDate: first.add(const Duration(days: 30)),
                firstDate: first,
                lastDate: DateTime(today.year + 5),
                helpText: l.carePlanAnotherDate,
              );
              if (picked != null) notifier.addBoosterDate(picked);
            },
            child: Text(l.careAddBoosterDate),
          ),
        ),
      ],
    );
  }
}
