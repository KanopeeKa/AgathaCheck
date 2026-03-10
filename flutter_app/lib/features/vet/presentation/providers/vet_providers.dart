import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import '../../data/datasources/vet_remote_datasource.dart';
import '../../data/repositories/vet_repository_impl.dart';
import '../../domain/entities/vet.dart';
import '../../domain/repositories/vet_repository.dart';
import '../../domain/usecases/create_vet.dart';
import '../../domain/usecases/delete_vet.dart';
import '../../domain/usecases/get_all_vets.dart';
import '../../domain/usecases/update_vet.dart';

/// Provider for the [VetRemoteDataSource] instance.
///
/// Creates a [VetRemoteDataSourceImpl] configured with the
/// base URL from [apiBaseUrlProvider].
final vetRemoteDataSourceProvider = Provider<VetRemoteDataSource>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return VetRemoteDataSourceImpl(baseUrl: baseUrl);
});

/// Provider for the [VetRepository] instance.
///
/// Creates a [VetRepositoryImpl] backed by the remote data source
/// from [vetRemoteDataSourceProvider].
final vetRepositoryProvider = Provider<VetRepository>((ref) {
  final dataSource = ref.watch(vetRemoteDataSourceProvider);
  return VetRepositoryImpl(dataSource);
});

/// Provider for the [GetAllVets] use case.
final getAllVetsUseCaseProvider = Provider<GetAllVets>((ref) {
  return GetAllVets(ref.watch(vetRepositoryProvider));
});

/// Provider for the [CreateVet] use case.
final createVetUseCaseProvider = Provider<CreateVet>((ref) {
  return CreateVet(ref.watch(vetRepositoryProvider));
});

/// Provider for the [UpdateVet] use case.
final updateVetUseCaseProvider = Provider<UpdateVet>((ref) {
  return UpdateVet(ref.watch(vetRepositoryProvider));
});

/// Provider for the [DeleteVet] use case.
final deleteVetUseCaseProvider = Provider<DeleteVet>((ref) {
  return DeleteVet(ref.watch(vetRepositoryProvider));
});

/// Notifier that manages the list of veterinarians.
///
/// Provides methods to create, update, delete, and refresh the
/// list of [Vet] entities. Automatically refreshes the list
/// after each mutation.
class VetListNotifier extends AsyncNotifier<List<Vet>> {
  @override
  Future<List<Vet>> build() async {
    return ref.read(getAllVetsUseCaseProvider).call();
  }

  /// Refreshes the veterinarian list by re-fetching from the data source.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  /// Creates a new [vet] and refreshes the list.
  Future<void> createVet(Vet vet) async {
    await ref.read(createVetUseCaseProvider).call(vet);
    await refresh();
  }

  /// Updates an existing [vet] and refreshes the list.
  Future<void> updateVet(Vet vet) async {
    await ref.read(updateVetUseCaseProvider).call(vet);
    await refresh();
  }

  /// Deletes the veterinarian with the given [id] and refreshes the list.
  Future<void> deleteVet(String id) async {
    await ref.read(deleteVetUseCaseProvider).call(id);
    await refresh();
  }
}

/// Provider for the [VetListNotifier] that exposes the list of veterinarians.
final vetListProvider =
    AsyncNotifierProvider<VetListNotifier, List<Vet>>(VetListNotifier.new);
