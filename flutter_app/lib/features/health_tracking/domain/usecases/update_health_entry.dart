import '../entities/health_entry.dart';
import '../repositories/health_repository.dart';

/// Use case for updating an existing health entry.
class UpdateHealthEntry {
  /// Creates an [UpdateHealthEntry] use case with the given [repository].
  const UpdateHealthEntry(this.repository);

  /// The repository to update the entry in.
  final HealthRepository repository;

  /// Executes the use case, updating and returning the [HealthEntry].
  Future<HealthEntry> call(HealthEntry entry) {
    return repository.updateEntry(entry);
  }
}
