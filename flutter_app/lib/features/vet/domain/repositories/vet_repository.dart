import '../entities/vet.dart';

/// Abstract repository interface for veterinarian data operations.
///
/// Defines the contract that data-layer implementations must fulfill
/// to provide CRUD operations for [Vet] entities.
abstract class VetRepository {
  /// Retrieves all veterinarians.
  Future<List<Vet>> getAllVets();

  /// Retrieves a single veterinarian by [id].
  ///
  /// Returns `null` if no veterinarian with the given [id] is found.
  Future<Vet?> getVet(String id);

  /// Creates a new veterinarian record.
  ///
  /// Returns the created [Vet] with server-assigned fields populated.
  Future<Vet> createVet(Vet vet);

  /// Updates an existing veterinarian record.
  ///
  /// Returns the updated [Vet].
  Future<Vet> updateVet(Vet vet);

  /// Deletes the veterinarian with the given [id].
  Future<void> deleteVet(String id);
}
