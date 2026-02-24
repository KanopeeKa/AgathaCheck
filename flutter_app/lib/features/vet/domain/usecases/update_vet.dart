import '../entities/vet.dart';
import '../repositories/vet_repository.dart';

/// Use case for updating an existing veterinarian.
///
/// Delegates to [VetRepository.updateVet] to persist
/// changes to a [Vet] record.
class UpdateVet {
  /// Creates an [UpdateVet] use case with the given [repository].
  const UpdateVet(this.repository);

  /// The repository used to update the veterinarian.
  final VetRepository repository;

  /// Executes the use case to update the given [vet].
  ///
  /// Returns the updated [Vet] with any server-modified fields.
  Future<Vet> call(Vet vet) {
    return repository.updateVet(vet);
  }
}
