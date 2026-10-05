import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/pet_care_sync.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../../core/weight/weight_unit.dart';
import '../../../../core/weight/weight_unit_preference.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/auth/auth.dart';
import '../../data/datasources/weight_remote_datasource.dart';
import '../../data/repositories/weight_repository_impl.dart';
import '../../domain/entities/weight_entry.dart';
import '../../domain/entities/weight_fulfilment_candidates.dart';
import '../../domain/entities/weight_overview.dart';
import '../../domain/entities/weight_write_outcomes.dart';
import '../../domain/repositories/weight_repository.dart';
import '../../domain/weight_entry_sort.dart';

export '../../../../core/weight/weight_unit.dart';

/// Query key for fulfilment candidates.
typedef WeightFulfilmentQuery = ({String petId, DateTime date});

final weightOverviewProvider = FutureProvider.autoDispose
    .family<WeightOverview, String>((ref, petId) async {
      final repo = ref.read(weightRepositoryProvider);
      final token = ref.read(authProvider).accessToken;
      if (token == null) {
        throw StateError('Not signed in');
      }
      return repo.getOverview(petId, token);
    });

final weightFulfilmentCandidatesProvider = FutureProvider.autoDispose
    .family<WeightFulfilmentCandidates, WeightFulfilmentQuery>((
      ref,
      query,
    ) async {
      final repo = ref.read(weightRepositoryProvider);
      final token = ref.read(authProvider).accessToken;
      if (token == null) {
        throw StateError('Not signed in');
      }
      return repo.getFulfilmentCandidates(
        query.petId,
        calendarDateOnly(query.date),
        token,
      );
    });

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

  Future<void> _refreshList() async {
    final repo = ref.read(weightRepositoryProvider);
    final token = _token;
    if (token == null) return;
    state = AsyncValue.data(
      sortWeightEntriesNewestFirst(await repo.getEntries(arg, token)),
    );
  }

  Future<WeightSaveOutcome> saveEntry({
    required WeightEntry entry,
    String? fulfilsOccurrenceId,
    bool isUpdate = false,
  }) async {
    final repo = ref.read(weightRepositoryProvider);
    final token = _token;
    if (token == null) {
      throw StateError('Not signed in');
    }
    final normalized = entry.copyWith(date: calendarDateOnly(entry.date));
    final WeightSaveOutcome outcome;
    if (fulfilsOccurrenceId != null && fulfilsOccurrenceId.isNotEmpty) {
      outcome = await repo.createEntryWithFulfilment(
        normalized,
        fulfilsOccurrenceId,
        token,
      );
    } else if (isUpdate) {
      final updated = await repo.updateEntry(normalized, token);
      outcome = WeightSaveOutcome(entry: updated);
    } else {
      final created = await repo.createEntry(normalized, token);
      outcome = WeightSaveOutcome(entry: created);
    }
    await _afterWrite();
    await _refreshList();
    return outcome;
  }

  Future<WeightSaveOutcome> fulfilExisting(
    String weightEntryId,
    String occurrenceId,
  ) async {
    final repo = ref.read(weightRepositoryProvider);
    final token = _token;
    if (token == null) throw StateError('Not signed in');
    final outcome = await repo.fulfilEntry(weightEntryId, occurrenceId, token);
    await _afterWrite();
    await _refreshList();
    return outcome;
  }

  Future<WeightDeleteOutcome> deleteEntry(String id) async {
    final repo = ref.read(weightRepositoryProvider);
    final token = _token;
    if (token == null) throw StateError('Not signed in');
    final outcome = await repo.deleteEntry(id, token);
    await _afterWrite();
    await _refreshList();
    return outcome;
  }

  Future<void> undoFulfilment({
    required String careEntryId,
    required String undoToken,
  }) async {
    final repo = ref.read(weightRepositoryProvider);
    final token = _token;
    if (token == null) throw StateError('Not signed in');
    await repo.scheduleUndo(careEntryId, undoToken, token);
    await _afterWrite();
    await _refreshList();
  }

  @Deprecated('Use saveEntry')
  Future<void> addEntry(WeightEntry entry) async {
    await saveEntry(entry: entry);
  }

  Future<void> refresh() async {
    await _refreshList();
  }
}

final weightEntriesNotifierProvider =
    AsyncNotifierProvider.family<
      WeightEntriesNotifier,
      List<WeightEntry>,
      String
    >(WeightEntriesNotifier.new);
