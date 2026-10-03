import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// "If done after the due date" (D2, D-CSM-026 v4): Keep · Skip the next
/// date · Move this and following. No "Ask me": completion never asks.
class LateCompletionChoiceField extends StatelessWidget {
  const LateCompletionChoiceField({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowShift = true,
  });

  /// `keep`, `skip_next`, `shift_following`; null shows Keep.
  final String? value;
  final ValueChanged<String?> onChanged;

  /// Move this and following applies to a Fixed schedule only.
  final bool allowShift;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final options = <String, String>{
      'keep': l.careIfDoneLateKeep,
      'skip_next': l.careIfDoneLateSkip,
      if (allowShift) 'shift_following': l.careIfDoneLateShift,
    };
    final current = options.containsKey(value) ? value! : 'keep';
    return DropdownButtonFormField<String>(
      key: const Key('care_item_if_done_late'),
      initialValue: current,
      decoration: InputDecoration(labelText: l.careIfDoneLateTitle),
      items: [
        for (final e in options.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: (choice) => onChanged(choice == 'keep' ? null : choice),
    );
  }
}
