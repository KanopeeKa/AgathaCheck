import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';

/// Whether the item belongs on the **Closed care** list (CARE-STATUS-R-021, R-024).
bool isClosedCareListEntry(HealthEntry entry) {
  if (entry.status == 'closed' || entry.status == 'completed') return true;
  return isHealthEntrySeriesClosed(entry);
}

List<HealthEntry> sortClosedCareEntries(List<HealthEntry> entries) {
  final sorted = [...entries];
  sorted.sort((a, b) {
    final aUser = a.status == 'closed';
    final bUser = b.status == 'closed';
    if (aUser != bUser) return aUser ? -1 : 1;
    final aDate = a.updatedAt ?? a.completedOn ?? a.startDate;
    final bDate = b.updatedAt ?? b.completedOn ?? b.startDate;
    return bDate.compareTo(aDate);
  });
  return sorted;
}

List<HealthEntry> partitionClosedCareEntries(List<HealthEntry> entries) {
  return sortClosedCareEntries(entries.where(isClosedCareListEntry).toList());
}
