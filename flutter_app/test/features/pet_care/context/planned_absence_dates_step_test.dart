import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/pet_care/context/presentation/widgets/planned_absence_dates_step.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  test('formatRangeDisplay shows dash when dates are missing', () {
    final l = lookupAppLocalizations(const Locale('en'));

    expect(
      PlannedAbsenceDatesStep.formatRangeDisplay(
        l,
        startsOn: null,
        endsOn: null,
      ),
      '—',
    );
  });

  test('formatRangeDisplay shows localized range when both dates set', () {
    final l = lookupAppLocalizations(const Locale('en'));
    final start = DateTime(2026, 9, 18);
    final end = DateTime(2026, 9, 25);

    expect(
      PlannedAbsenceDatesStep.formatRangeDisplay(
        l,
        startsOn: start,
        endsOn: end,
      ),
      '18/09/2026 – 25/09/2026',
    );
  });
}
