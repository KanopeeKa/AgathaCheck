import 'package:mockito/mockito.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_history_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';

class MockHealthRepository extends Mock implements HealthRepository {
  static final _fallbackEntry = HealthEntry(
    id: '',
    petId: '',
    name: '',
    type: HealthEntryType.medication,
    frequency: HealthFrequency.once,
    startDate: DateTime(2025),
    nextDueDate: DateTime(2025),
  );

  @override
  Future<List<HealthEntry>> getEntries({String? petId, HealthEntryType? type}) =>
      super.noSuchMethod(
        Invocation.method(#getEntries, [], {#petId: petId, #type: type}),
        returnValue: Future.value(<HealthEntry>[]),
      ) as Future<List<HealthEntry>>;

  @override
  Future<HealthEntry> createEntry(HealthEntry? entry) => super.noSuchMethod(
        Invocation.method(#createEntry, [entry]),
        returnValue: Future.value(_fallbackEntry),
      ) as Future<HealthEntry>;

  @override
  Future<HealthEntry> updateEntry(HealthEntry? entry) => super.noSuchMethod(
        Invocation.method(#updateEntry, [entry]),
        returnValue: Future.value(_fallbackEntry),
      ) as Future<HealthEntry>;

  @override
  Future<void> deleteEntry(String? id) => super.noSuchMethod(
        Invocation.method(#deleteEntry, [id]),
        returnValue: Future.value(),
      ) as Future<void>;

  @override
  Future<HealthEntry> markTaken(String? id, {String? notes}) =>
      super.noSuchMethod(
        Invocation.method(#markTaken, [id], {#notes: notes}),
        returnValue: Future.value(_fallbackEntry),
      ) as Future<HealthEntry>;

  @override
  Future<HealthEntry> undoComplete(String? id) => super.noSuchMethod(
        Invocation.method(#undoComplete, [id]),
        returnValue: Future.value(_fallbackEntry),
      ) as Future<HealthEntry>;

  @override
  Future<List<HealthHistoryEntry>> getHistory(String? entryId) =>
      super.noSuchMethod(
        Invocation.method(#getHistory, [entryId]),
        returnValue: Future.value(<HealthHistoryEntry>[]),
      ) as Future<List<HealthHistoryEntry>>;

  @override
  Future<String> exportCsv({String? petId}) => super.noSuchMethod(
        Invocation.method(#exportCsv, [], {#petId: petId}),
        returnValue: Future.value(''),
      ) as Future<String>;
}
