import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:pet_profile_app/features/health_tracking/data/datasources/health_remote_datasource.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_entry_model.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_history_model.dart';
import 'package:pet_profile_app/features/health_tracking/data/repositories/health_repository_impl.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';

@GenerateMocks([HealthRemoteDataSource])
import 'health_repository_impl_test.mocks.dart';

void main() {
  late MockHealthRemoteDataSource mockDataSource;
  late HealthRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockHealthRemoteDataSource();
    repository = HealthRepositoryImpl(mockDataSource);
  });

  final testModel = HealthEntryModel(
    id: 'test-1',
    petId: 'pet-1',
    name: 'Heartgard',
    type: HealthEntryType.medication,
    dosage: '1 tablet',
    frequency: HealthFrequency.monthly,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime(2025, 2, 1),
  );

  group('getEntries', () {
    test('returns entries from data source', () async {
      when(mockDataSource.getEntries(petId: null, type: null))
          .thenAnswer((_) async => [testModel]);

      final result = await repository.getEntries();
      expect(result, hasLength(1));
      expect(result.first.name, 'Heartgard');
    });

    test('passes filter parameters to data source', () async {
      when(mockDataSource.getEntries(petId: 'pet-1', type: 'medication'))
          .thenAnswer((_) async => [testModel]);

      await repository.getEntries(
          petId: 'pet-1', type: HealthEntryType.medication);
      verify(mockDataSource.getEntries(petId: 'pet-1', type: 'medication'))
          .called(1);
    });
  });

  group('getEntry', () {
    test('returns entry from data source', () async {
      when(mockDataSource.getEntry('test-1'))
          .thenAnswer((_) async => testModel);

      final result = await repository.getEntry('test-1');
      expect(result?.name, 'Heartgard');
    });

    test('returns null when not found', () async {
      when(mockDataSource.getEntry('missing'))
          .thenAnswer((_) async => null);

      final result = await repository.getEntry('missing');
      expect(result, isNull);
    });
  });

  group('createEntry', () {
    test('delegates to data source', () async {
      when(mockDataSource.createEntry(any))
          .thenAnswer((_) async => testModel);

      final result = await repository.createEntry(testModel);
      expect(result.name, 'Heartgard');
      verify(mockDataSource.createEntry(any)).called(1);
    });
  });

  group('updateEntry', () {
    test('delegates to data source', () async {
      when(mockDataSource.updateEntry(any))
          .thenAnswer((_) async => testModel);

      final result = await repository.updateEntry(testModel);
      expect(result.name, 'Heartgard');
    });
  });

  group('deleteEntry', () {
    test('delegates to data source', () async {
      when(mockDataSource.deleteEntry('test-1'))
          .thenAnswer((_) async {});

      await repository.deleteEntry('test-1');
      verify(mockDataSource.deleteEntry('test-1')).called(1);
    });
  });

  group('markTaken', () {
    test('delegates to data source with notes', () async {
      when(mockDataSource.markTaken('test-1', notes: 'Done'))
          .thenAnswer((_) async => testModel);

      final result = await repository.markTaken('test-1', notes: 'Done');
      expect(result.name, 'Heartgard');
    });
  });

  group('getHistory', () {
    test('returns history from data source', () async {
      final historyModel = HealthHistoryModel(
        id: 'h-1',
        entryId: 'test-1',
        takenAt: DateTime(2025, 1, 15),
        notes: 'Administered',
      );
      when(mockDataSource.getHistory('test-1'))
          .thenAnswer((_) async => [historyModel]);

      final result = await repository.getHistory('test-1');
      expect(result, hasLength(1));
      expect(result.first.notes, 'Administered');
    });
  });

  group('exportCsv', () {
    test('returns CSV string from data source', () async {
      when(mockDataSource.exportCsv(petId: null))
          .thenAnswer((_) async => 'Name,Type\nHeartgard,medication');

      final result = await repository.exportCsv();
      expect(result, contains('Heartgard'));
    });
  });
}
