/// User-facing weight units. Stored values are always kg (D-WM-008).
enum WeightUnit { kg, lb }

/// Canonical kg per pound (NIST).
const double kgPerLb = 0.45359237;

/// Converts a stored kg value to the user's display unit.
double toDisplay(double kg, WeightUnit unit) {
  return unit == WeightUnit.lb ? kg / kgPerLb : kg;
}

/// Converts a value entered in [unit] to kg for the API.
double toKg(double value, WeightUnit unit) {
  return unit == WeightUnit.lb ? value * kgPerLb : value;
}

String unitLabel(WeightUnit unit) => unit == WeightUnit.kg ? 'kg' : 'lb';

WeightUnit weightUnitFromWire(String? wire) {
  if (wire == 'lb') return WeightUnit.lb;
  return WeightUnit.kg;
}

String weightUnitToWire(WeightUnit unit) => unit == WeightUnit.lb ? 'lb' : 'kg';

/// One decimal place plus unit label (e.g. `12.5 kg`).
String formatWeight(double kg, WeightUnit unit) {
  final display = toDisplay(kg, unit);
  return '${display.toStringAsFixed(1)} ${unitLabel(unit)}';
}
