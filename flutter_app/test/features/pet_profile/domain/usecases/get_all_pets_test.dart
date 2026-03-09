import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/usecases/get_all_pets.dart';

import '../../../../helpers/mock_pet_repository.dart';

void main() {
  late MockPetRepository mockRepository;
  late GetAllPets getAllPets;

  setUp(() {
    mockRepository = MockPetRepository();
    getAllPets = GetAllPets(mockRepository);
  });

  const testPets = [
    Pet(id: '1', name: 'Buddy', species: 'Dog', breed: 'Labrador'),
    Pet(id: '2', name: 'Whiskers', species: 'Cat', breed: 'Persian'),
  ];

  test('should return all pets from repository', () async {
    when(mockRepository.getAllPets()).thenAnswer((_) async => testPets);

    final result = await getAllPets();

    expect(result, equals(testPets));
    expect(result.length, 2);
    verify(mockRepository.getAllPets()).called(1);
  });

  test('should return empty list when no pets exist', () async {
    when(mockRepository.getAllPets()).thenAnswer((_) async => []);

    final result = await getAllPets();

    expect(result, isEmpty);
  });
}
