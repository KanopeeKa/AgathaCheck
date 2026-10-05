import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../core/weight/weight_unit_preference.dart';
import 'package:pet_profile_app/features/weight_tracking/weight_tracking.dart';

@Deprecated('Removed in weight-unify-care W8')
class WeightTrackingController {
  final WidgetRef ref;
  WeightTrackingController(this.ref);

  Future<void> addWeightEntry(String petId, WeightEntry entry) async {
    final normalized = entry.copyWith(date: calendarDateOnly(entry.date));
    await ref
        .read(weightEntriesNotifierProvider(petId).notifier)
        .addEntry(normalized);
  }

  Future<void> deleteWeightEntry(String petId, String entryId) async {
    await ref
        .read(weightEntriesNotifierProvider(petId).notifier)
        .deleteEntry(entryId);
  }

  Future<void> setWeightUnit(String petId, WeightUnit unit) {
    return ref.read(setWeightUnitPreferenceProvider)(unit);
  }
}
