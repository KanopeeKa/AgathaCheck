import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/vet_remote_datasource.dart';
import '../../data/repositories/vet_repository_impl.dart';
import '../../domain/entities/vet.dart';
import '../../domain/repositories/vet_repository.dart';
import '../../domain/usecases/create_vet.dart';
import '../../domain/usecases/delete_vet.dart';
import '../../domain/usecases/get_all_vets.dart';
import '../../domain/usecases/update_vet.dart';

final vetApiBaseUrlProvider = Provider<String>((ref) {
  if (kIsWeb) {
    return '';
  }
  return 'http://localhost:5000';
});

final vetRemoteDataSourceProvider = Provider<VetRemoteDataSource>((ref) {
  final baseUrl = ref.watch(vetApiBaseUrlProvider);
  return VetRemoteDataSourceImpl(baseUrl: baseUrl);
});

final vetRepositoryProvider = Provider<VetRepository>((ref) {
  final dataSource = ref.watch(vetRemoteDataSourceProvider);
  return VetRepositoryImpl(dataSource);
});

final getAllVetsUseCaseProvider = Provider<GetAllVets>((ref) {
  return GetAllVets(ref.watch(vetRepositoryProvider));
});

final createVetUseCaseProvider = Provider<CreateVet>((ref) {
  return CreateVet(ref.watch(vetRepositoryProvider));
});

final updateVetUseCaseProvider = Provider<UpdateVet>((ref) {
  return UpdateVet(ref.watch(vetRepositoryProvider));
});

final deleteVetUseCaseProvider = Provider<DeleteVet>((ref) {
  return DeleteVet(ref.watch(vetRepositoryProvider));
});

class VetListNotifier extends AsyncNotifier<List<Vet>> {
  @override
  Future<List<Vet>> build() async {
    return ref.read(getAllVetsUseCaseProvider).call();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> createVet(Vet vet) async {
    await ref.read(createVetUseCaseProvider).call(vet);
    await refresh();
  }

  Future<void> updateVet(Vet vet) async {
    await ref.read(updateVetUseCaseProvider).call(vet);
    await refresh();
  }

  Future<void> deleteVet(String id) async {
    await ref.read(deleteVetUseCaseProvider).call(id);
    await refresh();
  }
}

final vetListProvider =
    AsyncNotifierProvider<VetListNotifier, List<Vet>>(VetListNotifier.new);
