import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/pet_timeline_remote_datasource.dart';
import '../../domain/entities/pet_timeline_segment.dart';
import '../widgets/pet_timeline/pet_timeline_list_builder.dart';
import 'pet_providers.dart';

final petTimelineDataSourceProvider = Provider<PetTimelineRemoteDataSource>((
  ref,
) {
  return PetTimelineRemoteDataSource(baseUrl: ref.watch(apiBaseUrlProvider));
});

final petTimelineProvider =
    FutureProvider.family<List<PetTimelineSegment>, String>((ref, petId) async {
      final token = await ref.read(authProvider.notifier).getValidAccessToken();
      if (token == null) return [];
      final ds = ref.watch(petTimelineDataSourceProvider);
      return ds.fetchTimeline(petId, token);
    });

final petTimelineListProvider =
    FutureProvider.family<List<PetTimelineSegment>, String>((ref, petId) async {
      final pet = await ref.watch(petByIdProvider(petId).future);
      final segments = await ref.watch(petTimelineProvider(petId).future);
      return buildPetTimelineList(pet: pet, apiSegments: segments);
    });

Future<void> createPetTimelineManualEntry(
  WidgetRef ref,
  String petId, {
  required String title,
  required String description,
  required String startDate,
  String? endDate,
}) async {
  final token = await ref.read(authProvider.notifier).getValidAccessToken();
  if (token == null) return;
  await ref
      .read(petTimelineDataSourceProvider)
      .createManualEntry(
        petId,
        token,
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
      );
  ref.invalidate(petTimelineProvider(petId));
  ref.invalidate(petTimelineListProvider(petId));
}

Future<void> updatePetTimelineManualEntry(
  WidgetRef ref,
  String petId,
  String entryId, {
  required String title,
  required String description,
  required String startDate,
  String? endDate,
}) async {
  final token = await ref.read(authProvider.notifier).getValidAccessToken();
  if (token == null) return;
  await ref
      .read(petTimelineDataSourceProvider)
      .updateManualEntry(
        petId,
        entryId,
        token,
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
      );
  ref.invalidate(petTimelineProvider(petId));
  ref.invalidate(petTimelineListProvider(petId));
}

Future<void> deletePetTimelineManualEntry(
  WidgetRef ref,
  String petId,
  String entryId,
) async {
  final token = await ref.read(authProvider.notifier).getValidAccessToken();
  if (token == null) return;
  await ref
      .read(petTimelineDataSourceProvider)
      .deleteManualEntry(petId, entryId, token);
  ref.invalidate(petTimelineProvider(petId));
  ref.invalidate(petTimelineListProvider(petId));
}
