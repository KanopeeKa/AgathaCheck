import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pet_profile/domain/entities/care_family.dart';
import '../../../pet_profile/presentation/controllers/weight_tracking_controller.dart';
import '../../../pet_profile/presentation/screens/widgets/add_weight_entry_sheet.dart';
import '../../../weight_tracking/presentation/providers/weight_providers.dart';
import '../../domain/entities/command_outcome.dart';
import '../../domain/entities/health_entry.dart';
import '../controllers/care_schedule_controller.dart';

/// Weight monitoring rhythms complete via linked weight observation (CP-2).
class WeightOccurrenceCareActions {
  const WeightOccurrenceCareActions._();

  static bool isWeightRhythm(HealthEntry entry) =>
      entry.careFamily == CareFamily.weightMonitoring;

  static Future<CommandOutcome?> persistWeightCompletion(
    WidgetRef ref,
    HealthEntry entry,
    String occurrenceId, {
    required double weightKg,
    required DateTime date,
    String notes = '',
  }) {
    return ref.read(careScheduleControllerProvider).completeWeightOccurrence(
      petId: entry.petId,
      entryId: entry.id,
      occurrenceId: occurrenceId,
      weightKg: weightKg,
      date: date,
      notes: notes,
    );
  }

  /// Opens [AddWeightEntrySheet] bound to [occurrenceId]; returns true when saved.
  static Future<bool> showWeightEntrySheetForOccurrence(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
    String occurrenceId,
  ) async {
    final unit = ref.read(weightUnitProvider(entry.petId));
    var saved = false;
    await showAddWeightEntrySheet(
      context: context,
      petId: entry.petId,
      unit: unit,
      controller: WeightTrackingController(ref),
      onSave: (weightKg, date, notes) async {
        final outcome = await persistWeightCompletion(
          ref,
          entry,
          occurrenceId,
          weightKg: weightKg,
          date: date,
          notes: notes,
        );
        if (outcome != null) {
          ref.invalidate(weightEntriesNotifierProvider(entry.petId));
        }
        saved = outcome != null;
      },
    );
    return saved;
  }
}
