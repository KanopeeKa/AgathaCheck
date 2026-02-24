import '../repositories/vet_repository.dart';

/// Use case for deleting a veterinarian.
///
/// Delegates to [VetRepository.deleteVet] to remove
/// the veterinarian record identified by its ID.
class DeleteVet {
  /// Creates a [DeleteVet] use case with the given [repository].
  const DeleteVet(this.repository);

  /// The repository used to delete the veterinarian.
  final VetRepository repository;

  /// Executes the use case to delete the veterinarian with the given [id].
  Future<void> call(String id) {
    return repository.deleteVet(id);
  }
}
