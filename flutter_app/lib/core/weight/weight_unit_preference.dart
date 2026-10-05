import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'weight_unit.dart';

/// Default no-op; overridden in [main.dart] from the signed-in user's profile.
final weightUnitPreferenceProvider = Provider<WeightUnit>(
  (ref) => WeightUnit.kg,
);

/// Persists the user's unit via `PUT /api/auth/me`; overridden at composition.
final setWeightUnitPreferenceProvider =
    Provider<Future<void> Function(WeightUnit)>((ref) {
      return (_) async {};
    });
