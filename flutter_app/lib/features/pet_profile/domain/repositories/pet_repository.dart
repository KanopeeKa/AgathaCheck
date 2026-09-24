import '../entities/pet.dart';
import '../entities/pet_list_fetch_result.dart';

/// Abstract repository interface for pet profile operations.
///
/// This defines the contract that any data source implementation
/// must fulfill. The domain layer depends only on this interface,
/// not on concrete implementations.
abstract class PetRepository {
  /// Retrieves all stored pet profiles.
  ///
  /// Prefer [fetchAllPets] when UI needs stale/offline metadata.
  Future<List<Pet>> getAllPets();

  /// Loads pets with explicit source/stale metadata (D2 hybrid offline reads).
  Future<PetListFetchResult> fetchAllPets();

  /// Retrieves a single pet by its [id].
  ///
  /// Returns `null` if no pet with the given [id] exists.
  Future<Pet?> getPetById(String id);

  /// Adds a new pet profile.
  ///
  /// Returns the added [Pet] with its assigned ID.
  Future<Pet> addPet(Pet pet);

  /// Updates an existing pet profile.
  ///
  /// Returns the updated [Pet].
  Future<Pet> updatePet(Pet pet);

  /// Deletes a pet profile by its [id].
  Future<void> deletePet(String id);

  /// Best-effort cascade delete of pet-related data, then removes the pet.
  Future<void> deletePetWithDataCleanup(String id);

  /// Persists passed-away on the server and notifies collaborators.
  /// Returns whether any collaborators were notified.
  Future<bool> markPassedAway(Pet pet);
}
