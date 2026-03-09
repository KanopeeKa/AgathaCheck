import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pet_profile_app/features/vet/domain/entities/vet.dart';
import 'package:pet_profile_app/features/vet/domain/usecases/get_all_vets.dart';

import '../../../../helpers/mock_vet_repository.dart';

void main() {
  late MockVetRepository mockRepository;
  late GetAllVets getAllVets;

  setUp(() {
    mockRepository = MockVetRepository();
    getAllVets = GetAllVets(mockRepository);
  });

  const testVets = [
    Vet(id: 'vet-1', name: 'Dr. Smith'),
    Vet(id: 'vet-2', name: 'Dr. Jones'),
  ];

  test('should get all vets from repository', () async {
    when(mockRepository.getAllVets()).thenAnswer((_) async => testVets);

    final result = await getAllVets();

    expect(result, equals(testVets));
    verify(mockRepository.getAllVets()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return empty list when no vets exist', () async {
    when(mockRepository.getAllVets()).thenAnswer((_) async => []);

    final result = await getAllVets();

    expect(result, isEmpty);
    verify(mockRepository.getAllVets()).called(1);
  });

  test('should propagate repository exceptions', () async {
    when(mockRepository.getAllVets()).thenThrow(Exception('Network error'));

    expect(() => getAllVets(), throwsException);
  });
}
