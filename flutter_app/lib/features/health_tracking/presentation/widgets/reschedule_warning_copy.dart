import '../../../../l10n/app_localizations.dart';

/// Maps server `warnings[]` objects to user-facing copy (D-ACP-009).
List<String> rescheduleWarningMessages(
  AppLocalizations l,
  List<Map<String, dynamic>> warnings,
) {
  final messages = <String>[];
  for (final warning in warnings) {
    final code = warning['code'] as String? ?? '';
    switch (code) {
      case 'earlier_only_later_move':
        messages.add(l.rescheduleEarlierOnlyLaterCaution);
        break;
      case 'outside_flexibility':
        final flexibility = warning['flexibility'] as String? ?? '';
        final careSource = warning['care_source'] as String? ?? '';
        if (flexibility == 'earlier_only') {
          messages.add(l.rescheduleEarlierOnlyLaterCaution);
        } else if (careSource == 'vet_instruction'
            || careSource == 'treatment_schedule') {
          messages.add(l.rescheduleVetScheduleCaution);
        } else {
          messages.add(l.rescheduleFlexibilityCaution);
        }
        break;
      case 'interval_changed':
        final x = warning['previous_gap_days'];
        final y = warning['usual_gap_days'];
        if (x is int && y is int) {
          messages.add(l.rescheduleGapWarning(x, y));
        }
        break;
      default:
        break;
    }
  }
  return messages;
}
