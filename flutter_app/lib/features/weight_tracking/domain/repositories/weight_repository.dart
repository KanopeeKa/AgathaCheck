import '../entities/weight_entry.dart';

abstract class WeightRepository {
  Future<List<WeightEntry>> getEntries(String petId, String token);
  Future<WeightEntry> createEntry(WeightEntry entry, String token);
  Future<WeightEntry> updateEntry(WeightEntry entry, String token);
  Future<void> deleteEntry(String id, String token);
  Future<WeightEntry?> getLatestWeight(String petId, String token);
}
