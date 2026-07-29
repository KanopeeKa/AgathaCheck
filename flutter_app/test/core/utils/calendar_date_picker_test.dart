import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/utils/calendar_date_picker.dart';

void main() {
  group('calendarDatePickerLocale', () {
    test('uses GB locale for English', () {
      expect(
        calendarDatePickerLocale(const Locale('en')),
        const Locale('en', 'GB'),
      );
    });

    test('uses FR locale for French', () {
      expect(
        calendarDatePickerLocale(const Locale('fr')),
        const Locale('fr', 'FR'),
      );
    });
  });
}
