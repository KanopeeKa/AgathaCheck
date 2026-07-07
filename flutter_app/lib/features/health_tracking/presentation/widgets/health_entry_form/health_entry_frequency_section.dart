import 'package:flutter/material.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../controllers/health_entry_form_controller.dart';
import '../../../domain/entities/health_entry.dart';
import '../../../domain/entities/recurrence_anchor.dart';
import '../recurrence_anchor_toggle.dart';
import 'health_entry_frequency_labels.dart';

/// Frequency, interval, repeat-end, and recurrence-anchor fields for the health entry form.
class HealthEntryFrequencySection extends StatelessWidget {
  const HealthEntryFrequencySection({
    super.key,
    required this.frequency,
    required this.frequencyInterval,
    required this.repeatEndDate,
    required this.recurrenceAnchor,
    required this.controller,
  });

  final HealthFrequency frequency;
  final int frequencyInterval;
  final DateTime? repeatEndDate;
  final RecurrenceAnchor recurrenceAnchor;
  final HealthEntryFormController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<HealthFrequency>(
          value: frequency,
          decoration: InputDecoration(labelText: l.frequency),
          items: HealthFrequency.values
              .where((f) => f != HealthFrequency.custom)
              .map(
                (f) => DropdownMenuItem(
                  value: f,
                  child: Text(healthEntryFrequencyLabel(l, f)),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) controller.setFrequency(val);
          },
        ),
        if (frequency != HealthFrequency.once) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: frequencyInterval.clamp(1, 12),
                  decoration: InputDecoration(labelText: l.every),
                  items: List.generate(12, (i) => i + 1)
                      .map(
                        (n) => DropdownMenuItem(value: n, child: Text('$n')),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) controller.setFrequencyInterval(val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: InputDecorator(
                  decoration: InputDecoration(labelText: l.period),
                  child: Text(
                    healthEntryPeriodLabel(l, frequency, frequencyInterval),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (frequency != HealthFrequency.once) ...[
          const SizedBox(height: 16),
          InputDecorator(
            decoration: InputDecoration(labelText: l.repeatEndsBy),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(l.never),
                  selected: repeatEndDate == null,
                  onSelected: (_) => controller.setRepeatEndDate(null),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(
                    repeatEndDate != null
                        ? formatHealthEntryCalendarDate(repeatEndDate!)
                        : l.pickADate,
                  ),
                  selected: repeatEndDate != null,
                  onSelected: (_) async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: repeatEndDate ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      controller.setRepeatEndDate(calendarDateOnly(picked));
                    }
                  },
                ),
              ],
            ),
          ),
        ],
        if (frequency != HealthFrequency.once) ...[
          const SizedBox(height: 16),
          RecurrenceAnchorToggle(
            value: recurrenceAnchor,
            onChanged: controller.setRecurrenceAnchor,
          ),
        ],
      ],
    );
  }
}
