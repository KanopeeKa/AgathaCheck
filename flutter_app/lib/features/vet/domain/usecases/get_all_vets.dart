import '../entities/vet.dart';
import '../repositories/vet_repository.dart';

/// Use case for retrieving all veterinarians.
///
/// Delegates to [VetRepository.getAllVets] to fetch
/// the complete list of [Vet] records.
class GetAllVets {
  /// Creates a [GetAllVets] use case with the given [repository].
  const GetAllVets(this.repository);

  /// The repository used to retrieve veterinarians.
  final VetRepository repository;

  /// Executes the use case to get all veterinarians.
  ///
  /// Returns a list of all [Vet] entities.
  Future<List<Vet>> call() {
    return repository.getAllVets();
  }
}
