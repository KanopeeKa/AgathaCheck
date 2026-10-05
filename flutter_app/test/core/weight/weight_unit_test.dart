import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/weight/weight_unit.dart';

void main() {
  group('FW-1 weight_unit.dart', () {
    test('conversions round-trip 22.0 lb at one decimal', () {
      const lb = 22.0;
      final kg = toKg(lb, WeightUnit.lb);
      final back = toDisplay(kg, WeightUnit.lb);
      expect(back.toStringAsFixed(1), '22.0');
    });

    test('formatWeight shows one decimal and unit', () {
      expect(formatWeight(10.0, WeightUnit.kg), '10.0 kg');
      expect(formatWeight(toKg(22.0, WeightUnit.lb), WeightUnit.lb), '22.0 lb');
    });

    test('weightUnitFromWire defaults to kg', () {
      expect(weightUnitFromWire(null), WeightUnit.kg);
      expect(weightUnitFromWire('lb'), WeightUnit.lb);
      expect(weightUnitToWire(WeightUnit.lb), 'lb');
    });
  });
}
