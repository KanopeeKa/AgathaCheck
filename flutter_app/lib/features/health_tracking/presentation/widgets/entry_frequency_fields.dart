import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../domain/entities/health_entry.dart';
import 'entry_form_labels.dart';

/// Frequency, interval, and repeat-end fields shared by health and other event forms.
class EntryFrequencyFields extends StatelessWidget {
  const EntryFrequencyFields({
    super.key,
    required this.frequency,
    required this.frequencyInterval,
    required this.repeatEndDate,
    required this.onFrequencyChanged,
    required this.onIntervalChanged,
    required this.onRepeatEndChanged,
  });

  final HealthFrequency frequency;
  final int frequencyInterval;
  final DateTime? repeatEndDate;
  final ValueChanged<HealthFrequency> onFrequencyChanged;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<DateTime?> onRepeatEndChanged;

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
              .map((f) {
            return DropdownMenuItem(
              value: f,
              child: Text(entryFrequencyLabel(l, f)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onFrequencyChanged(val);
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
                      .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) onIntervalChanged(val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: InputDecorator(
                  decoration: InputDecoration(labelText: l.period),
                  child: Text(
                    entryPeriodLabel(l, frequency, frequencyInterval),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: InputDecoration(labelText: l.repeatEndsBy),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(l.never),
                  selected: repeatEndDate == null,
                  onSelected: (_) => onRepeatEndChanged(null),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(repeatEndDate != null
                      ? formatEntryDate(repeatEndDate!)
                      : l.pickADate),
                  selected: repeatEndDate != null,
                  onSelected: (_) async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: repeatEndDate ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) onRepeatEndChanged(calendarDateOnly(picked));
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
