import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Reminder lead-time field shared by health and other event forms.
class EntryRemindBeforeField extends StatelessWidget {
  const EntryRemindBeforeField({
    super.key,
    required this.remindDaysBefore,
    required this.onChanged,
  });

  final int remindDaysBefore;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l.remindBefore,
              prefixIcon: const Icon(Icons.notifications_active, size: 20),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    key: const Key('remind_days_field'),
                    initialValue: remindDaysBefore.toString(),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed >= 0) onChanged(parsed);
                    },
                  ),
                ),
                Text(
                  l.daysBefore,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
