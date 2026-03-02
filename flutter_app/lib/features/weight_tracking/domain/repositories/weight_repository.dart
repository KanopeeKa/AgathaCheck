import '../entities/weight_entry.dart';

abstract class WeightRepository {
  Future<List<WeightEntry>> getEntries(String petId);
  Future<WeightEntry> createEntry(WeightEntry entry);
  Future<WeightEntry> updateEntry(WeightEntry entry);
  Future<void> deleteEntry(int id);
  Future<WeightEntry?> getLatestWeight(String petId);
}
