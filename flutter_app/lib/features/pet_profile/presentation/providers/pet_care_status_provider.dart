import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import '../../domain/entities/care_status.dart';
import '../../domain/services/care_status_service.dart';

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
