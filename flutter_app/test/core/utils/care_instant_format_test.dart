import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:pet_profile_app/core/utils/care_instant_format.dart';

void main() {
  test('formatCareWallClockTime24 uses HH:mm', () {
    final instant = DateTime(2026, 11, 3, 22, 7);
    expect(formatCareWallClockTime24(instant), '22:07');
  });

  test('formatCareScheduledTime24 normalises API time', () {
    expect(formatCareScheduledTime24('09:00:00'), '09:00');
    expect(formatCareScheduledTime24('8:05'), '08:05');
    expect(formatCareScheduledTime24(null), '');
  });

  test('formatCareRecordedCalendarDate uses dd MMM yy', () {
    final instant = DateTime(2026, 11, 3, 22, 7);
    expect(
      formatCareRecordedCalendarDate(instant),
      DateFormat('dd MMM yy').format(instant),
    );
  });
}
