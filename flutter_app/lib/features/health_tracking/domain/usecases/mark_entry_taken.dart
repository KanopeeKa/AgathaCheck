import '../entities/health_entry.dart';
import '../repositories/health_repository.dart';

/// Use case for marking a health entry as taken/administered.
///
/// Records a history entry and advances the next due date
/// based on the entry's frequency.
class MarkEntryTaken {
  /// Creates a [MarkEntryTaken] use case with the given [repository].
  const MarkEntryTaken(this.repository);

  /// The repository to update.
  final HealthRepository repository;

  /// Executes the use case, marking the entry with [id] as taken.
  Future<HealthEntry> call(String id, {String notes = ''}) {
    return repository.markTaken(id, notes: notes);
  }
}
