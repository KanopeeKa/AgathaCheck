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
                    onChanged: (v) {
                      final val = int.tryParse(v);
                      if (val != null && val >= 0) onChanged(val);
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
