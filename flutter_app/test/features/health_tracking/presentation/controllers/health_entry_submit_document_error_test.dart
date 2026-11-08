import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/controllers/health_entry_form_outcomes.dart';
import 'package:pet_profile_app/l10n/app_localizations_en.dart';

void main() {
  test(
    'HealthEntrySubmitDocumentError is distinct from generic submit error',
    () {
      final documentError = HealthEntrySubmitDocumentError();
      final genericError = HealthEntrySubmitError(
        Exception('raw upload stack'),
      );

      expect(documentError, isA<HealthEntrySubmitOutcome>());
      expect(genericError, isA<HealthEntrySubmitError>());
      expect(documentError, isNot(isA<HealthEntrySubmitError>()));
    },
  );

  test('documentAddFailed is user-safe copy', () {
    final l = AppLocalizationsEn();
    expect(l.documentAddFailed, isNot(contains('Exception')));
    expect(l.documentAddFailed, contains('document'));
  });
}
