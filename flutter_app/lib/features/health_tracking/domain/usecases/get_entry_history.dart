import '../entities/health_history_entry.dart';
import '../repositories/health_repository.dart';

/// Use case for retrieving the administration history of a health entry.
class GetEntryHistory {
  /// Creates a [GetEntryHistory] use case with the given [repository].
  const GetEntryHistory(this.repository);

  /// The repository to retrieve history from.
  final HealthRepository repository;

  /// Executes the use case, returning a list of [HealthHistoryEntry] objects.
  Future<List<HealthHistoryEntry>> call(String entryId) {
    return repository.getHistory(entryId);
  }
}
