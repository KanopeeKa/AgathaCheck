import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/usecases/add_pet.dart';

import '../../../../helpers/mock_pet_repository.dart';

void main() {
  late MockPetRepository mockRepository;
  late AddPet addPet;

  setUp(() {
    mockRepository = MockPetRepository();
    addPet = AddPet(mockRepository);
  });

  final testPet = Pet(
    id: 'test-id-1',
    name: 'Buddy',
    species: 'Dog',
    breed: 'Golden Retriever',
    dateOfBirth: DateTime(2022, 1, 15),
    weight: 30.0,
    bio: 'A friendly dog',
  );

  test('should add pet via repository', () async {
    when(mockRepository.addPet(testPet)).thenAnswer((_) async => testPet);

    final result = await addPet(testPet);

    expect(result, equals(testPet));
    verify(mockRepository.addPet(testPet)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should propagate repository exceptions', () async {
    when(mockRepository.addPet(testPet)).thenThrow(Exception('Storage error'));

    expect(() => addPet(testPet), throwsException);
  });
}
