import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../domain/entities/care_status.dart';
import '../../domain/services/care_status_service.dart';

const _careStatusService = CareStatusService();

final petCareStatusSummaryProvider = Provider.family<CareStatusSummary, String>(
  (ref, petId) {
    final entries = ref.watch(healthEntriesNotifierProvider).valueOrNull ??
        const <HealthEntry>[];
    return _careStatusService.evaluate(
      petId: petId,
      entries: entries,
      now: DateTime.now(),
    );
  },
);
