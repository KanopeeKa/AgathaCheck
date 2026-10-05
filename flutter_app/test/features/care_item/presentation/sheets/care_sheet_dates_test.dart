import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/care_item/presentation/sheets/care_sheet_dates.dart';

void main() {
  test('defaultPlanAnotherDate skips reserved open days', () {
    final asOf = DateTime(2026, 7, 1);
    final reserved = [DateTime(2026, 7, 2), DateTime(2026, 7, 3)];
    final picked = defaultPlanAnotherDate(asOf: asOf, reservedDates: reserved);
    expect(calendarDateOnly(picked), DateTime(2026, 7, 4));
  });
}
