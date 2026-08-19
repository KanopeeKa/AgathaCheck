import re

with open('flutter_app/lib/features/health_tracking/presentation/widgets/health_entry_form/health_entry_remind_field.dart', 'r') as f:
    content = f.read()

new_content = """import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

class HealthEntryRemindField extends StatelessWidget {
  const HealthEntryRemindField({
    super.key,
    required this.remindDaysBefore,
    required this.onChanged,
  });

  final int remindDaysBefore;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: l.remindBefore,
        prefixIcon: const Icon(Icons.notifications_active, size: 20),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Wrap(
          spacing: 8.0,
          children: [
            _buildChip(context, 0, 'None'),
            _buildChip(context, 1, '1 day'),
            _buildChip(context, 3, '3 days'),
            _buildChip(context, 7, '1 week'),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, int value, String label) {
    final isSelected = remindDaysBefore == value;
    final theme = Theme.of(context);
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onChanged(value);
        }
      },
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
      ),
    );
  }
}
"""

with open('flutter_app/lib/features/health_tracking/presentation/widgets/health_entry_form/health_entry_remind_field.dart', 'w') as f:
    f.write(new_content)
