import '../entities/pet.dart';
import '../repositories/pet_repository.dart';

/// Use case for retrieving all pet profiles.
///
/// Encapsulates the business logic for fetching the complete
/// list of stored pets from the repository.
class GetAllPets {
  /// Creates a [GetAllPets] use case with the given [repository].
  const GetAllPets(this.repository);

  /// The repository used to fetch pet data.
  final PetRepository repository;

  /// Executes the use case, returning all stored pets.
  Future<List<Pet>> call() => repository.getAllPets();
}
