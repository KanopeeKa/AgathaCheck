import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Undo button copy for the Care date screen (D-OCC-011).
String occurrenceUndoLabel(AppLocalizations l, CareLastAction? action) {
  if (action?.isCompletionDateChange == true) {
    return l.careUndoDateChange;
  }
  return l.snackbarUndo;
}
