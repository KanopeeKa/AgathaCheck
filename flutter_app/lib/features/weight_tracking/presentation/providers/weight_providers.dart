import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../data/datasources/weight_remote_datasource.dart';
import '../../data/repositories/weight_repository_impl.dart';
import '../../domain/entities/weight_entry.dart';
import '../../domain/repositories/weight_repository.dart';

final weightRemoteDataSourceProvider =
    Provider<WeightRemoteDataSource>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return WeightRemoteDataSourceImpl(baseUrl: baseUrl);
});

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  final dataSource = ref.watch(weightRemoteDataSourceProvider);
  return WeightRepositoryImpl(dataSource);
});

final weightEntriesProvider =
    FutureProvider.family<List<WeightEntry>, String>((ref, petId) async {
  final repo = ref.watch(weightRepositoryProvider);
  return repo.getEntries(petId);
});

final latestWeightProvider =
    FutureProvider.family<WeightEntry?, String>((ref, petId) async {
  final repo = ref.watch(weightRepositoryProvider);
  return repo.getLatestWeight(petId);
});

class WeightEntriesNotifier extends FamilyAsyncNotifier<List<WeightEntry>, String> {
  @override
  Future<List<WeightEntry>> build(String arg) async {
    final repo = ref.read(weightRepositoryProvider);
    return repo.getEntries(arg);
  }

  Future<void> addEntry(WeightEntry entry) async {
    final repo = ref.read(weightRepositoryProvider);
    await repo.createEntry(entry);
    ref.invalidate(latestWeightProvider(arg));
    state = AsyncValue.data(await repo.getEntries(arg));
  }

  Future<void> deleteEntry(int id) async {
    final repo = ref.read(weightRepositoryProvider);
    await repo.deleteEntry(id);
    ref.invalidate(latestWeightProvider(arg));
    state = AsyncValue.data(await repo.getEntries(arg));
  }

  Future<void> refresh() async {
    final repo = ref.read(weightRepositoryProvider);
    ref.invalidate(latestWeightProvider(arg));
    state = AsyncValue.data(await repo.getEntries(arg));
  }
}

final weightEntriesNotifierProvider = AsyncNotifierProvider.family<
    WeightEntriesNotifier, List<WeightEntry>, String>(
  WeightEntriesNotifier.new,
);
