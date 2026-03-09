import 'dart:typed_data';

import 'package:mockito/mockito.dart';
import 'package:pet_profile_app/features/health_tracking/data/datasources/health_remote_datasource.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_entry_model.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_history_model.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';

class MockHealthRemoteDataSource extends Mock
    implements HealthRemoteDataSource {
  static final _fallbackModel = HealthEntryModel(
    id: '',
    petId: '',
    name: '',
    type: HealthEntryType.medication,
    frequency: HealthFrequency.once,
    startDate: DateTime(2025),
    nextDueDate: DateTime(2025),
  );

  @override
  Future<List<HealthEntryModel>> getEntries({String? petId, String? type}) =>
      super.noSuchMethod(
        Invocation.method(#getEntries, [], {#petId: petId, #type: type}),
        returnValue: Future.value(<HealthEntryModel>[]),
      ) as Future<List<HealthEntryModel>>;

  @override
  Future<HealthEntryModel?> getEntry(String? id) => super.noSuchMethod(
        Invocation.method(#getEntry, [id]),
        returnValue: Future.value(null),
        returnValueForMissingStub: Future.value(null),
      ) as Future<HealthEntryModel?>;

  @override
  Future<HealthEntryModel> createEntry(HealthEntryModel? entry) =>
      super.noSuchMethod(
        Invocation.method(#createEntry, [entry]),
        returnValue: Future.value(_fallbackModel),
      ) as Future<HealthEntryModel>;

  @override
  Future<HealthEntryModel> updateEntry(HealthEntryModel? entry) =>
      super.noSuchMethod(
        Invocation.method(#updateEntry, [entry]),
        returnValue: Future.value(_fallbackModel),
      ) as Future<HealthEntryModel>;

  @override
  Future<void> deleteEntry(String? id) => super.noSuchMethod(
        Invocation.method(#deleteEntry, [id]),
        returnValue: Future.value(),
      ) as Future<void>;

  @override
  Future<HealthEntryModel> markTaken(String? id, {String? notes}) =>
      super.noSuchMethod(
        Invocation.method(#markTaken, [id], {#notes: notes}),
        returnValue: Future.value(_fallbackModel),
      ) as Future<HealthEntryModel>;

  @override
  Future<HealthEntryModel> undoComplete(String? id) => super.noSuchMethod(
        Invocation.method(#undoComplete, [id]),
        returnValue: Future.value(_fallbackModel),
      ) as Future<HealthEntryModel>;

  @override
  Future<List<HealthHistoryModel>> getHistory(String? entryId) =>
      super.noSuchMethod(
        Invocation.method(#getHistory, [entryId]),
        returnValue: Future.value(<HealthHistoryModel>[]),
      ) as Future<List<HealthHistoryModel>>;

  @override
  Future<String> exportCsv({String? petId}) => super.noSuchMethod(
        Invocation.method(#exportCsv, [], {#petId: petId}),
        returnValue: Future.value(''),
      ) as Future<String>;

  @override
  Future<List<EventPhoto>> getPhotos(String? entryId) => super.noSuchMethod(
        Invocation.method(#getPhotos, [entryId]),
        returnValue: Future.value(<EventPhoto>[]),
      ) as Future<List<EventPhoto>>;

  @override
  Future<EventPhoto> uploadPhoto(
          String? entryId, Uint8List? bytes, String? filename,
          {String? caption}) =>
      super.noSuchMethod(
        Invocation.method(#uploadPhoto, [entryId, bytes, filename],
            {#caption: caption}),
        returnValue: Future.value(
            EventPhoto(id: 0, eventId: '', photoPath: '')),
      ) as Future<EventPhoto>;

  @override
  Future<void> deletePhoto(String? entryId, int? photoId) =>
      super.noSuchMethod(
        Invocation.method(#deletePhoto, [entryId, photoId]),
        returnValue: Future.value(),
      ) as Future<void>;
}
