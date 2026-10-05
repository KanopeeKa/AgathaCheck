import '../../../../care_taxonomy/domain/care_importance.dart';
import '../../../../care_taxonomy/domain/care_setting.dart';
import 'health_entry_care_classification_labels.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/health_entry.dart';
import '../../../domain/entities/recurrence_anchor.dart';

/// One-line Advanced settings summary (D-CIE-027), e.g.
/// "At home · Essential · After it's done · Keep the next date".
String healthEntryAdvancedSettingsSummary(
  AppLocalizations l, {
  required CareSetting careSetting,
  required CareImportance careImportance,
  required HealthFrequency frequency,
  required RecurrenceAnchor recurrenceAnchor,
  required String? lateCompletionChoice,
}) {
  final parts = <String>[
    healthEntryCareSettingLabel(l, careSetting),
    healthEntryCareImportanceLabel(l, careImportance),
  ];
  if (frequency != HealthFrequency.once) {
    parts.add(
      recurrenceAnchor == RecurrenceAnchor.fromDueDate
          ? l.recurrenceFromDueDate
          : l.recurrenceFromCompletion,
    );
    parts.add(_lateChoiceSummary(l, lateCompletionChoice));
  }
  return parts.join(' · ');
}

String _lateChoiceSummary(AppLocalizations l, String? choice) {
  switch (choice) {
    case 'skip_next':
      return l.careIfDoneLateSkip;
    case 'shift_following':
      return l.careIfDoneLateShift;
    case 'keep':
    case null:
      return l.careIfDoneLateKeep;
    default:
      return l.careIfDoneLateKeep;
  }
}
