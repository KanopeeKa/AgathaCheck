import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/health_occurrence.dart';
import 'health_providers.dart';

/// Open (pending) occurrences for a health entry series.
final entryOccurrencesProvider =
    FutureProvider.family<List<HealthOccurrence>, String>((ref, entryId) {
      return ref.read(healthRepositoryProvider).getOpenOccurrences(entryId);
    });
