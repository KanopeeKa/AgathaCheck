import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/pet_care_sync.dart';
import '../../../../core/weight/weight_unit.dart';
import '../../../../core/weight/weight_unit_preference.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/weight_remote_datasource.dart';
import '../../data/repositories/weight_repository_impl.dart';
import '../../domain/entities/weight_entry.dart';
import '../../domain/repositories/weight_repository.dart';
import '../../domain/weight_entry_sort.dart';

export '../../../../core/weight/weight_unit.dart';

/// Stub for W6 (`GET /api/weight-entries/overview`).
final weightOverviewProvider = FutureProvider.autoDispose
    .family<Object?, String>((ref, petId) async => null);

/// Query key for fulfilment candidates (W6).
typedef WeightFulfilmentQuery = ({String petId, DateTime date});

/// Stub for W6 (`GET /api/weight-entries/fulfilment-candidates`).
final weightFulfilmentCandidatesProvider = FutureProvider.autoDispose
    .family<Object?, WeightFulfilmentQuery>((ref, query) async => null);

@Deprecated(
  'Use weightUnitPreferenceProvider (per user, not per pet). Removed in W8.',
)
final weightUnitProvider = Provider.family<WeightUnit, String>((ref, petId) {
  return ref.watch(weightUnitPreferenceProvider);
});

@Deprecated('Use toDisplay from core/weight/weight_unit.dart')
double convertWeight(double kg, WeightUnit unit) => toDisplay(kg, unit);

@Deprecated('Use toKg from core/weight/weight_unit.dart')
double convertToKg(double value, WeightUnit unit) => toKg(value, unit);

@Deprecated('Use unitLabel from core/weight/weight_unit.dart')
String weightUnitLabel(WeightUnit unit) => unitLabel(unit);

final weightRemoteDataSourceProvider = Provider<WeightRemoteDataSource>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return WeightRemoteDataSourceImpl(
    baseUrl: baseUrl,
    client: ref.watch(authHttpClientProvider),
  );
});

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  final dataSource = ref.watch(weightRemoteDataSourceProvider);
  return WeightRepositoryImpl(dataSource);
});

class WeightEntriesNotifier
    extends FamilyAsyncNotifier<List<WeightEntry>, String> {
  @override
  Future<List<WeightEntry>> build(String arg) async {
    final repo = ref.read(weightRepositoryProvider);
    final auth = ref.read(authProvider);
    final token = auth.accessToken;
    if (token == null) return [];
    return sortWeightEntriesNewestFirst(await repo.getEntries(arg, token));
  }

  String? get _token => ref.read(authProvider).accessToken;

  Future<void> _afterWrite() async {
    final sync = ref.read(petCareSyncProvider);
    await sync.weightChanged(arg);
    await sync.careChanged(arg);
  }

  Future<void> addEntry(WeightEntry entry) async {
    final repo = ref.read(weightRepositoryProvider);
    final token = _token;
    if (token == null) return;
    await repo.createEntry(entry, token);
    await _afterWrite();
    state = AsyncValue.data(
      sortWeightEntriesNewestFirst(await repo.getEntries(arg, token)),
    );
  }

  Future<void> deleteEntry(String id) async {
    final repo = ref.read(weightRepositoryProvider);
    final token = _token;
    if (token == null) return;
    await repo.deleteEntry(id, token);
    await _afterWrite();
    state = AsyncValue.data(
      sortWeightEntriesNewestFirst(await repo.getEntries(arg, token)),
    );
  }

  Future<void> refresh() async {
    final repo = ref.read(weightRepositoryProvider);
    final token = _token;
    if (token == null) return;
    state = AsyncValue.data(
      sortWeightEntriesNewestFirst(await repo.getEntries(arg, token)),
    );
  }
}

final weightEntriesNotifierProvider =
    AsyncNotifierProvider.family<
      WeightEntriesNotifier,
      List<WeightEntry>,
      String
    >(WeightEntriesNotifier.new);
