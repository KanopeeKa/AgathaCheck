import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../data/datasources/weight_remote_datasource.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import '../../data/repositories/weight_repository_impl.dart';
import '../../domain/entities/weight_entry.dart';
import '../../domain/repositories/weight_repository.dart';

enum WeightUnit { kg, lb }

const double _kgToLb = 2.20462;

double convertWeight(double kg, WeightUnit unit) {
  return unit == WeightUnit.lb ? kg * _kgToLb : kg;
}

double convertToKg(double value, WeightUnit unit) {
  return unit == WeightUnit.lb ? value / _kgToLb : value;
}

String weightUnitLabel(WeightUnit unit) {
  return unit == WeightUnit.kg ? 'kg' : 'lb';
}

final weightUnitProvider =
    StateNotifierProvider.family<WeightUnitNotifier, WeightUnit, String>(
        (ref, petId) => WeightUnitNotifier(petId));

class WeightUnitNotifier extends StateNotifier<WeightUnit> {
  WeightUnitNotifier(this._petId) : super(WeightUnit.kg) {
    _load();
  }

  final String _petId;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('pet_${_petId}_weightUnit');
    if (stored == 'lb') {
      state = WeightUnit.lb;
    }
  }

  Future<void> setUnit(WeightUnit unit) async {
    state = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pet_${_petId}_weightUnit', unit.name);
  }
}

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
