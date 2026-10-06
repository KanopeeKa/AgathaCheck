import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/occurrence/occurrence_undo_label.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  test(
    'occurrenceUndoLabel uses date-change copy when last action was edit',
    () {
      final l = lookupAppLocalizations(const Locale('en'));
      expect(
        occurrenceUndoLabel(
          l,
          const CareLastAction(
            type: 'completion_date_changed',
            occurrenceId: 'o1',
          ),
        ),
        l.careUndoDateChange,
      );
      expect(
        occurrenceUndoLabel(
          l,
          const CareLastAction(type: 'completed', occurrenceId: 'o1'),
        ),
        l.snackbarUndo,
      );
    },
  );
}
