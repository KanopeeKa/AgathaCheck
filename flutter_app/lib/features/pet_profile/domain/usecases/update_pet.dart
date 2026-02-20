import '../entities/pet.dart';
import '../repositories/pet_repository.dart';

/// Use case for updating an existing pet profile.
///
/// Delegates the update operation to the repository.
class UpdatePet {
  /// Creates an [UpdatePet] use case with the given [repository].
  const UpdatePet(this.repository);

  /// The repository used to persist pet data.
  final PetRepository repository;

  /// Executes the use case, updating the given [pet] and returning it.
  Future<Pet> call(Pet pet) => repository.updatePet(pet);
}
