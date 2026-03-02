import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/pet_local_datasource.dart';
import '../../data/repositories/pet_repository_impl.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/pet_repository.dart';
import '../../domain/usecases/add_pet.dart';
import '../../domain/usecases/delete_pet.dart';
import '../../domain/usecases/get_all_pets.dart';
import '../../domain/usecases/update_pet.dart';

export '../../../../core/providers/shared_preferences_provider.dart';

/// Provider for the local data source, scoped to the current user.
final petLocalDataSourceProvider = Provider<PetLocalDataSource>((ref) {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  return PetLocalDataSourceImpl(ref.watch(sharedPreferencesProvider), userId: userId);
});

/// Provider for the pet repository.
final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepositoryImpl(ref.watch(petLocalDataSourceProvider));
});

/// Provider for the GetAllPets use case.
final getAllPetsUseCaseProvider = Provider<GetAllPets>((ref) {
  return GetAllPets(ref.watch(petRepositoryProvider));
});

/// Provider for the AddPet use case.
final addPetUseCaseProvider = Provider<AddPet>((ref) {
  return AddPet(ref.watch(petRepositoryProvider));
});

/// Provider for the UpdatePet use case.
final updatePetUseCaseProvider = Provider<UpdatePet>((ref) {
  return UpdatePet(ref.watch(petRepositoryProvider));
});

/// Provider for the DeletePet use case.
final deletePetUseCaseProvider = Provider<DeletePet>((ref) {
  return DeletePet(ref.watch(petRepositoryProvider));
});

/// Notifier that manages the list of pets with CRUD operations.
///
/// Provides reactive state management for the pet list,
/// automatically notifying listeners when the list changes.
class PetListNotifier extends AsyncNotifier<List<Pet>> {
  /// Loads all pets from the repository via the [GetAllPets] use case.
  @override
  Future<List<Pet>> build() async {
    final pets = await ref.read(getAllPetsUseCaseProvider).call();
    final needsMigration = pets.any((p) => p.colorValue == null);
    if (needsMigration) {
      final usedColors = <int>{};
      final updated = <Pet>[];
      for (final p in pets) {
        if (p.colorValue != null) {
          usedColors.add(p.colorValue!);
          updated.add(p);
        } else {
          int color = Pet.palette[0];
          for (final c in Pet.palette) {
            if (!usedColors.contains(c)) {
              color = c;
              break;
            }
          }
          usedColors.add(color);
          final patched = p.copyWith(colorValue: color);
          await ref.read(updatePetUseCaseProvider).call(patched);
          updated.add(patched);
        }
      }
      return updated;
    }
    return pets;
  }

  /// Adds a new pet with the given details.
  Future<void> addPet({
    required String name,
    required String species,
    String breed = '',
    double? age,
    double? weight,
    String? gender,
    String bio = '',
    String? photoPath,
    String? vetId,
  }) async {
    final existing = state.valueOrNull ?? [];
    final usedColors = existing
        .where((p) => p.colorValue != null)
        .map((p) => p.colorValue!)
        .toSet();
    int color = Pet.palette[0];
    for (final c in Pet.palette) {
      if (!usedColors.contains(c)) {
        color = c;
        break;
      }
    }
    final pet = Pet(
      id: const Uuid().v4(),
      name: name,
      species: species,
      breed: breed,
      age: age,
      weight: weight,
      gender: gender,
      bio: bio,
      photoPath: photoPath,
      vetId: vetId,
      colorValue: color,
    );
    await ref.read(addPetUseCaseProvider).call(pet);
    ref.invalidateSelf();
  }

  /// Updates an existing pet.
  Future<void> updatePet(Pet pet) async {
    await ref.read(updatePetUseCaseProvider).call(pet);
    ref.invalidateSelf();
  }

  /// Deletes a pet by its [id].
  Future<void> deletePet(String id) async {
    await ref.read(deletePetUseCaseProvider).call(id);
    ref.invalidateSelf();
  }
}

/// The main provider for the pet list state.
final petListProvider =
    AsyncNotifierProvider<PetListNotifier, List<Pet>>(PetListNotifier.new);

/// Provider that retrieves a single pet by ID.
final petByIdProvider = FutureProvider.family<Pet?, String>((ref, id) async {
  final repo = ref.watch(petRepositoryProvider);
  return repo.getPetById(id);
});
