import '../entities/vet.dart';
import '../repositories/vet_repository.dart';

/// Use case for creating a new veterinarian.
///
/// Delegates to [VetRepository.createVet] to persist
/// a new [Vet] record.
class CreateVet {
  /// Creates a [CreateVet] use case with the given [repository].
  const CreateVet(this.repository);

  /// The repository used to create the veterinarian.
  final VetRepository repository;

  /// Executes the use case to create the given [vet].
  ///
  /// Returns the newly created [Vet] with server-assigned fields.
  Future<Vet> call(Vet vet) {
    return repository.createVet(vet);
  }
}
