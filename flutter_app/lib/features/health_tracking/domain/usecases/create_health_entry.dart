import '../entities/health_entry.dart';
import '../repositories/health_repository.dart';

/// Use case for creating a new health entry.
class CreateHealthEntry {
  /// Creates a [CreateHealthEntry] use case with the given [repository].
  const CreateHealthEntry(this.repository);

  /// The repository to create the entry in.
  final HealthRepository repository;

  /// Executes the use case, creating and returning the new [HealthEntry].
  Future<HealthEntry> call(HealthEntry entry) {
    return repository.createEntry(entry);
  }
}
