import 'package:flutter/material.dart';

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
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 8,
          children: [
            _buildChip(context, value: 0, label: l.remindChipNone),
            _buildChip(context, value: 1, label: l.remindChipOneDay),
            _buildChip(context, value: 3, label: l.remindChipThreeDays),
            _buildChip(context, value: 7, label: l.remindChipOneWeek),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required int value,
    required String label,
  }) {
    final isSelected = remindDaysBefore == value;
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onChanged(value);
      },
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
      ),
    );
  }
}
