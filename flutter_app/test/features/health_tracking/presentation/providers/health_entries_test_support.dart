import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';

HealthEntry testHealthEntry(String id, {String petId = 'pet-1'}) => HealthEntry(
  id: id,
  petId: petId,
  name: 'Entry $id',
  type: HealthEntryType.medication,
  frequency: HealthFrequency.monthly,
  startDate: DateTime(2025, 1, 1),
  nextDueDate: DateTime(2025, 2, 1),
);

HealthOccurrence testOccurrence(String entryId, {String id = 'occ-1'}) =>
    HealthOccurrence(
      id: id,
      entryId: entryId,
      scheduledDate: DateTime(2025, 1, 15),
      status: 'pending',
    );

/// Minimal [HealthRepository] double for provider store tests.
class FakeHealthRepository implements HealthRepository {
  FakeHealthRepository({
    List<HealthEntry>? entries,
    this.getEntriesThrows = false,
    this.failNextGetEntries = false,
    this.getEntriesDelay,
  }) : entries = List<HealthEntry>.from(entries ?? const []);

  List<HealthEntry> entries;
  final bool getEntriesThrows;
  bool failNextGetEntries;
  final Duration? getEntriesDelay;

  var getEntriesCallCount = 0;
  var deleteCallCount = 0;
  var createCallCount = 0;
  var updateCallCount = 0;
  var closeEventCallCount = 0;
  var reopenEventCallCount = 0;
  var pauseCallCount = 0;
  var resumeCallCount = 0;
  var unmarkDoneCallCount = 0;
  var completeOccurrenceCallCount = 0;
  bool throwOnDelete = false;

  @override
  Future<List<HealthEntry>> getEntries({
    String? petId,
    HealthEntryType? type,
  }) async {
    getEntriesCallCount++;
    if (getEntriesDelay != null) {
      await Future<void>.delayed(getEntriesDelay!);
    }
    if (getEntriesThrows || failNextGetEntries) {
      failNextGetEntries = false;
      throw Exception('getEntries failed');
    }
    return List<HealthEntry>.from(entries);
  }

  @override
  Future<void> deleteEntry(String id) async {
    deleteCallCount++;
    if (throwOnDelete) {
      throw Exception('delete failed');
    }
    entries.removeWhere((e) => e.id == id);
  }

  @override
  Future<HealthEntry> createEntry(HealthEntry entry) async {
    createCallCount++;
    entries.add(entry);
    return entry;
  }

  @override
  Future<HealthEntry> updateEntry(HealthEntry entry) async {
    updateCallCount++;
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) entries[index] = entry;
    return entry;
  }

  @override
  Future<HealthEntry> closeEvent(String id) async {
    closeEventCallCount++;
    return entries.firstWhere((e) => e.id == id);
  }

  @override
  Future<HealthEntry> reopenEvent(String id) async {
    reopenEventCallCount++;
    return entries.firstWhere((e) => e.id == id);
  }

  @override
  Future<HealthEntry> pauseCareItem(String id) async {
    pauseCallCount++;
    return entries.firstWhere((e) => e.id == id);
  }

  @override
  Future<HealthEntry> resumeCareItem(String id) async {
    resumeCallCount++;
    return entries.firstWhere((e) => e.id == id);
  }

  @override
  Future<HealthEntry> unmarkDone(String id) async {
    unmarkDoneCallCount++;
    return entries.firstWhere((e) => e.id == id);
  }

  @override
  Future<List<HealthOccurrence>> getOpenOccurrences(String entryId) async {
    return [testOccurrence(entryId)];
  }

  @override
  Future<HealthOccurrence> completeOccurrence(
    String entryId,
    String occurrenceId, {
    String notes = '',
    DateTime? completedOn,
    bool skipEarlierMissed = false,
  }) async {
    completeOccurrenceCallCount++;
    return testOccurrence(entryId, id: occurrenceId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
