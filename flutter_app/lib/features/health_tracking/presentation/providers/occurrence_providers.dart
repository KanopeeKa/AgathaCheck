import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/health_occurrence.dart';
import '../../domain/occurrence_scheduling.dart';
import 'health_providers.dart';

/// Open (pending) occurrences for a health entry series.
final entryOccurrencesProvider =
    FutureProvider.family<List<HealthOccurrence>, String>((ref, entryId) {
      return ref.read(healthRepositoryProvider).getOpenOccurrences(entryId);
    });

/// Zone counts and list-row heads derived from open occurrences.
final occurrenceSummaryProvider =
    Provider.family<OccurrenceSummary, String>((ref, entryId) {
      final async = ref.watch(entryOccurrencesProvider(entryId));
      return async.when(
        data: (list) => summarizeOpenOccurrences(list, DateTime.now()),
        loading: () => const OccurrenceSummary(openCount: 0, missedCount: 0),
        error: (_, __) => const OccurrenceSummary(openCount: 0, missedCount: 0),
      );
    });
