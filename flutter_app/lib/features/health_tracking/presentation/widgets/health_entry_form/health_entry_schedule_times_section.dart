import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../controllers/health_entry_form_controller.dart';

/// Checkbox and time rows for scheduling doses at specific local times.
class HealthEntryScheduleTimesSection extends StatelessWidget {
  const HealthEntryScheduleTimesSection({
    super.key,
    required this.scheduleAtSpecificTimes,
    required this.scheduleTimes,
    required this.controller,
  });

  final bool scheduleAtSpecificTimes;
  final List<String> scheduleTimes;
  final HealthEntryFormController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          key: const Key('schedule_at_specific_times_checkbox'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.scheduleAtSpecificTimes),
          subtitle: Text(
            l.scheduleAtSpecificTimesHint,
            style: theme.textTheme.bodySmall,
          ),
          value: scheduleAtSpecificTimes,
          onChanged: (value) {
            controller.setScheduleAtSpecificTimes(value ?? false);
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (scheduleAtSpecificTimes) ...[
          const SizedBox(height: 8),
          ...List.generate(scheduleTimes.length, (index) {
            final time = scheduleTimes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: Key('schedule_time_picker_$index'),
                      onPressed: () => _pickTime(context, index, time),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(_formatTimeLabel(context, time)),
                      ),
                    ),
                  ),
                  if (scheduleTimes.length > 1)
                    IconButton(
                      key: Key('remove_schedule_time_$index'),
                      tooltip: l.removeScheduleTime,
                      onPressed: () => controller.removeScheduleTime(index),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                ],
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('add_schedule_time_button'),
              onPressed: controller.addScheduleTime,
              icon: const Icon(Icons.add),
              label: Text(l.addAnotherScheduleTime),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickTime(BuildContext context, int index, String current) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 8,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final normalized =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    controller.setScheduleTime(index, normalized);
  }

  String _formatTimeLabel(BuildContext context, String time) {
    final parts = time.split(':');
    if (parts.length < 2) return time;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final dt = DateTime(2000, 1, 1, hour, minute);
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(dt),
    );
  }
}
