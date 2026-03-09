import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:pet_profile_app/features/vet/data/models/vet_model.dart';
import 'package:pet_profile_app/features/vet/data/repositories/vet_repository_impl.dart';
import 'package:pet_profile_app/features/vet/domain/entities/vet.dart';

import '../../../../helpers/mock_vet_remote_datasource.dart';

void main() {
  late MockVetRemoteDataSource mockDataSource;
  late VetRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockVetRemoteDataSource();
    repository = VetRepositoryImpl(mockDataSource);
  });

  final testModel = VetModel(
    id: '1',
    name: 'Dr. Smith',
    phone: '555-1234',
    email: 'smith@vet.com',
    website: 'https://drsmith.com',
    address: '123 Main St',
    notes: 'Great vet',
  );

  final testVet = Vet(
    id: '1',
    name: 'Dr. Smith',
    phone: '555-1234',
    email: 'smith@vet.com',
    website: 'https://drsmith.com',
    address: '123 Main St',
    notes: 'Great vet',
  );

  group('getAllVets', () {
    test('returns list of vets from data source', () async {
      when(mockDataSource.getAllVets())
          .thenAnswer((_) async => [testModel]);

      final result = await repository.getAllVets();

      expect(result, hasLength(1));
      expect(result.first.name, 'Dr. Smith');
      verify(mockDataSource.getAllVets()).called(1);
    });

    test('returns empty list when data source returns empty', () async {
      when(mockDataSource.getAllVets())
          .thenAnswer((_) async => []);

      final result = await repository.getAllVets();

      expect(result, isEmpty);
    });
  });

  group('getVet', () {
    test('returns vet from data source', () async {
      when(mockDataSource.getVet('1'))
          .thenAnswer((_) async => testModel);

      final result = await repository.getVet('1');

      expect(result, isNotNull);
      expect(result!.name, 'Dr. Smith');
      verify(mockDataSource.getVet('1')).called(1);
    });

    test('returns null when data source returns null', () async {
      when(mockDataSource.getVet('missing'))
          .thenAnswer((_) async => null);

      final result = await repository.getVet('missing');

      expect(result, isNull);
      verify(mockDataSource.getVet('missing')).called(1);
    });
  });

  group('createVet', () {
    test('delegates to data source with VetModel', () async {
      when(mockDataSource.createVet(any))
          .thenAnswer((_) async => testModel);

      final result = await repository.createVet(testVet);

      expect(result.name, 'Dr. Smith');
      verify(mockDataSource.createVet(any)).called(1);
    });
  });

  group('updateVet', () {
    test('delegates to data source with VetModel', () async {
      when(mockDataSource.updateVet(any))
          .thenAnswer((_) async => testModel);

      final result = await repository.updateVet(testVet);

      expect(result.name, 'Dr. Smith');
      verify(mockDataSource.updateVet(any)).called(1);
    });
  });

  group('deleteVet', () {
    test('delegates to data source', () async {
      when(mockDataSource.deleteVet('1'))
          .thenAnswer((_) async {});

      await repository.deleteVet('1');

      verify(mockDataSource.deleteVet('1')).called(1);
    });
  });
}
