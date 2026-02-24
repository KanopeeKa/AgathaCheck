import '../entities/health_entry.dart';
import '../repositories/health_repository.dart';

/// Use case for retrieving health entries.
///
/// Supports optional filtering by pet ID and entry type.
class GetHealthEntries {
  /// Creates a [GetHealthEntries] use case with the given [repository].
  const GetHealthEntries(this.repository);

  /// The repository to retrieve entries from.
  final HealthRepository repository;

  /// Executes the use case, returning a list of [HealthEntry] objects.
  Future<List<HealthEntry>> call({String? petId, HealthEntryType? type}) {
    return repository.getEntries(petId: petId, type: type);
  }
}
