import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/health_remote_datasource.dart';
import '../../domain/entities/health_entry.dart';
import '../providers/health_providers.dart';

/// Single health entry for a pet, derived from the global entries list.
final petHealthEntryByIdProvider =
    Provider.family<AsyncValue<HealthEntry?>, ({String petId, String entryId})>(
  (ref, args) {
    return ref.watch(petHealthEntriesByIdProvider(args.petId)).whenData(
          (entries) =>
              entries.where((e) => e.id == args.entryId).firstOrNull,
        );
  },
);

/// Photos/documents attached to a health entry.
final healthEntryPhotosProvider =
    FutureProvider.autoDispose.family<List<EventPhoto>, String>((ref, entryId) {
  return ref.read(healthDataSourceProvider).getPhotos(entryId);
});
