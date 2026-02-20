import '../entities/pet.dart';
import '../repositories/pet_repository.dart';

/// Use case for adding a new pet profile.
///
/// Validates and delegates the creation of a new pet
/// to the repository.
class AddPet {
  /// Creates an [AddPet] use case with the given [repository].
  const AddPet(this.repository);

  /// The repository used to persist pet data.
  final PetRepository repository;

  /// Executes the use case, adding the given [pet] and returning it.
  Future<Pet> call(Pet pet) => repository.addPet(pet);
}
