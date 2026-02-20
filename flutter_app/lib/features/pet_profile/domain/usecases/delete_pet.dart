import '../repositories/pet_repository.dart';

/// Use case for deleting a pet profile.
///
/// Delegates the deletion to the repository using the pet's ID.
class DeletePet {
  /// Creates a [DeletePet] use case with the given [repository].
  const DeletePet(this.repository);

  /// The repository used to delete pet data.
  final PetRepository repository;

  /// Executes the use case, deleting the pet with the given [id].
  Future<void> call(String id) => repository.deletePet(id);
}
