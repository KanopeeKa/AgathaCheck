import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../weight_tracking/domain/entities/weight_entry.dart';
import '../../../../core/weight/weight_unit.dart';
import '../../../../core/weight/weight_unit_preference.dart';
import '../../../weight_tracking/presentation/providers/weight_providers.dart';

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
