import 'entities/weight_entry.dart';

/// Chronological order for charts: oldest first, then by recorded time.
int compareWeightEntriesChronological(WeightEntry a, WeightEntry b) {
  final byDate = a.date.compareTo(b.date);
  if (byDate != 0) return byDate;
  final aCreated = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final bCreated = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  return aCreated.compareTo(bCreated);
}

/// Newest-first order for history lists.
int compareWeightEntriesNewestFirst(WeightEntry a, WeightEntry b) =>
    compareWeightEntriesChronological(b, a);

List<WeightEntry> sortWeightEntriesNewestFirst(List<WeightEntry> entries) {
  return [...entries]..sort(compareWeightEntriesNewestFirst);
}

List<WeightEntry> sortWeightEntriesChronological(List<WeightEntry> entries) {
  return [...entries]..sort(compareWeightEntriesChronological);
}
