import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/weight_entry.dart';
import '../../../weight_tracking/presentation/providers/weight_providers.dart';

class WeightTrackingController {
  final WidgetRef ref;
  WeightTrackingController(this.ref);

  Future<void> addWeightEntry(String petId, WeightEntry entry) async {
    await ref.read(weightEntriesNotifierProvider(petId).notifier).addEntry(entry);
  }

  Future<void> deleteWeightEntry(String petId, int entryId) async {
    await ref.read(weightEntriesNotifierProvider(petId).notifier).deleteEntry(entryId);
  }

  void setWeightUnit(String petId, dynamic unit) {
    ref.read(weightUnitProvider(petId).notifier).setUnit(unit);
  }
}
