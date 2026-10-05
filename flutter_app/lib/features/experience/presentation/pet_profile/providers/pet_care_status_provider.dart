import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';

const _careStatusService = CareStatusService();

final petCareStatusSummaryProvider = Provider.family<CareStatusSummary, String>(
  (ref, petId) {
    final entries =
        ref.watch(healthEntriesNotifierProvider).valueOrNull ??
        const <HealthEntry>[];
    return _careStatusService.evaluate(
      petId: petId,
      entries: entries,
      now: DateTime.now(),
    );
  },
);
