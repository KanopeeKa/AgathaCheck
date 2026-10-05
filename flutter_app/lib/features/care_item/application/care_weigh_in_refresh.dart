import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/pet_care_sync.dart';
import '../domain/completion_requirements.dart';

/// Refreshes weight data after a weigh-in routine command (D-WM-016).
void refreshWeightAfterWeighInCommand(
  WidgetRef ref, {
  required String? careFamily,
  required String petId,
}) {
  if (careFamily != kWeightMonitoringFamily) return;
  ref.read(petCareSyncProvider).weightChanged(petId);
}
