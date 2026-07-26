import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/pet_timeline_remote_datasource.dart';
import '../../domain/entities/pet_timeline_segment.dart';

final petTimelineDataSourceProvider = Provider<PetTimelineRemoteDataSource>((ref) {
  return PetTimelineRemoteDataSource(baseUrl: ref.watch(apiBaseUrlProvider));
});

final petTimelineProvider = FutureProvider.family<List<PetTimelineSegment>, String>((
  ref,
  petId,
) async {
  final token = await ref.read(authProvider.notifier).getValidAccessToken();
  if (token == null) return [];
  final ds = ref.watch(petTimelineDataSourceProvider);
  return ds.fetchTimeline(petId, token);
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
  await ref.read(petTimelineDataSourceProvider).createManualEntry(
    petId,
    token,
    title: title,
    description: description,
    startDate: startDate,
    endDate: endDate,
  );
  ref.invalidate(petTimelineProvider(petId));
}
