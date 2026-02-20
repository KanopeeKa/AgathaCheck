import '../entities/pet.dart';

/// Abstract repository interface for pet profile operations.
///
/// This defines the contract that any data source implementation
/// must fulfill. The domain layer depends only on this interface,
/// not on concrete implementations.
abstract class PetRepository {
  /// Retrieves all stored pet profiles.
  Future<List<Pet>> getAllPets();

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
}
