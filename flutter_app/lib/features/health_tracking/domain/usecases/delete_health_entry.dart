import '../repositories/health_repository.dart';

/// Use case for deleting a health entry.
class DeleteHealthEntry {
  /// Creates a [DeleteHealthEntry] use case with the given [repository].
  const DeleteHealthEntry(this.repository);

  /// The repository to delete the entry from.
  final HealthRepository repository;

  /// Executes the use case, deleting the entry with the given [id].
  Future<void> call(String id) {
    return repository.deleteEntry(id);
  }
}
