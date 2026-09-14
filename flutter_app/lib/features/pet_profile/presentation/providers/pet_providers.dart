import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/providers/pet_weight_invalidation.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/pet_local_datasource.dart';
import '../../data/datasources/pet_remote_datasource.dart';
import '../../data/repositories/pet_repository_impl.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/pet_repository.dart';
import '../../domain/usecases/add_pet.dart';
import '../../domain/usecases/delete_pet.dart';
import '../../domain/usecases/get_all_pets.dart';
import '../../domain/usecases/update_pet.dart';

export '../../../../core/providers/shared_preferences_provider.dart';

final petLocalDataSourceProvider = Provider<PetLocalDataSource>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  return PetLocalDataSourceImpl(
    ref.watch(sharedPreferencesProvider),
    userId: userId,
  );
});

final petRemoteDataSourceProvider = Provider<PetRemoteDataSource>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return PetRemoteDataSourceImpl(
    baseUrl: baseUrl,
    client: ref.watch(authHttpClientProvider),
  );
});

final _accessTokenProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.accessToken;
});

final petRepositoryProvider = Provider<PetRepository>((ref) {
  final local = ref.watch(petLocalDataSourceProvider);
  final remote = ref.watch(petRemoteDataSourceProvider);
  final token = ref.watch(_accessTokenProvider);
  return PetRepositoryImpl(local, remoteDataSource: remote, token: token);
});

final getAllPetsUseCaseProvider = Provider<GetAllPets>((ref) {
  return GetAllPets(ref.watch(petRepositoryProvider));
});

final addPetUseCaseProvider = Provider<AddPet>((ref) {
  return AddPet(ref.watch(petRepositoryProvider));
});

final updatePetUseCaseProvider = Provider<UpdatePet>((ref) {
  return UpdatePet(ref.watch(petRepositoryProvider));
});

final deletePetUseCaseProvider = Provider<DeletePet>((ref) {
  return DeletePet(ref.watch(petRepositoryProvider));
});

class PetListNotifier extends AsyncNotifier<List<Pet>> {
  @override
  Future<List<Pet>> build() async {
    ref.watch(authProvider);
    return ref.read(getAllPetsUseCaseProvider).call();
  }

  Future<String> addPet({
    required String name,
    required String species,
    String breed = '',
    DateTime? dateOfBirth,
    double? weight,
    String? gender,
    String bio = '',
    String insurance = '',
    DateTime? neuteredDate,
    bool neuterDismissed = false,
    String chipId = '',
    bool chipDismissed = false,
    String? photoPath,
    String? vetId,
    String? organizationId,
  }) async {
    final pet = Pet(
      id: const Uuid().v4(),
      name: name,
      species: species,
      breed: breed,
      dateOfBirth: dateOfBirth,
      weight: weight,
      gender: gender,
      bio: bio,
      insurance: insurance,
      neuteredDate: neuteredDate,
      neuterDismissed: neuterDismissed,
      chipId: chipId,
      chipDismissed: chipDismissed,
      photoPath: photoPath,
      vetId: vetId,
      organizationId: organizationId,
    );
    await ref.read(addPetUseCaseProvider).call(pet);
    if (weight != null) {
      invalidateWeightEntryProviders(ref, pet.id);
    }
    ref.invalidateSelf();
    ref.invalidate(allPetsIncludingOrgProvider);
    return pet.id;
  }

  Future<void> updatePet(Pet pet) async {
    await ref.read(updatePetUseCaseProvider).call(pet);
    invalidateWeightEntryProviders(ref, pet.id);
    ref.invalidateSelf();
    ref.invalidate(allPetsIncludingOrgProvider);
  }

  Future<void> deletePet(String id) async {
    await ref.read(petRepositoryProvider).deletePetWithDataCleanup(id);
    ref.invalidateSelf();
    ref.invalidate(allPetsIncludingOrgProvider);
  }

  Future<bool> markPassedAway(String petId) async {
    final pets = state.valueOrNull ?? [];
    final pet = pets.where((p) => p.id == petId).firstOrNull;
    if (pet == null) return false;

    final hasSharedUsers = await ref
        .read(petRepositoryProvider)
        .markPassedAway(pet);
    ref.invalidateSelf();
    ref.invalidate(allPetsIncludingOrgProvider);
    return hasSharedUsers;
  }
}

final petListProvider = AsyncNotifierProvider<PetListNotifier, List<Pet>>(
  PetListNotifier.new,
);

final petByIdProvider = FutureProvider.family<Pet?, String>((ref, id) async {
  final pets = await ref.watch(petListProvider.future);
  return pets.where((p) => p.id == id).firstOrNull;
});

/// All pets visible to the user (owned, shared, foster, org) with local photo merge.
///
/// Uses [getAllPetsUseCaseProvider] so photos stored locally as `data:` URLs are
/// preserved — the raw `/api/pets/all` response omits them.
final allPetsIncludingOrgProvider = FutureProvider<List<Pet>>((ref) async {
  final token = ref.watch(_accessTokenProvider);
  if (token == null || token.isEmpty) return [];
  return ref.read(getAllPetsUseCaseProvider).call();
});
