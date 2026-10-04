import 'package:flutter/material.dart';

import '../../domain/entities/recurrence_anchor.dart';
import 'health_entry_form/schedule_type_field.dart';

/// @deprecated Use [ScheduleTypeField] in Advanced settings (B2 / F35).
class RecurrenceAnchorToggle extends StatelessWidget {
  const RecurrenceAnchorToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final RecurrenceAnchor value;
  final ValueChanged<RecurrenceAnchor> onChanged;

  @override
  Widget build(BuildContext context) {
    return ScheduleTypeField(value: value, onChanged: onChanged);
  }
}
