import '../entities/weight_entry.dart';
import '../entities/weight_fulfilment_candidates.dart';
import '../entities/weight_overview.dart';
import '../entities/weight_write_outcomes.dart';

abstract class WeightRepository {
  Future<List<WeightEntry>> getEntries(String petId, String token);
  Future<WeightEntry> createEntry(WeightEntry entry, String token);
  Future<WeightSaveOutcome> createEntryWithFulfilment(
    WeightEntry entry,
    String fulfilsOccurrenceId,
    String token,
  );
  Future<WeightSaveOutcome> fulfilEntry(
    String weightEntryId,
    String occurrenceId,
    String token,
  );
  Future<WeightEntry> updateEntry(WeightEntry entry, String token);
  Future<WeightDeleteOutcome> deleteEntry(String id, String token);
  Future<WeightEntry?> getLatestWeight(String petId, String token);
  Future<WeightOverview> getOverview(String petId, String token);
  Future<WeightFulfilmentCandidates> getFulfilmentCandidates(
    String petId,
    DateTime date,
    String token,
  );
  Future<void> scheduleUndo(String careEntryId, String undoToken, String token);
}
