import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/usecases/update_pet.dart';

import '../../../../helpers/mock_pet_repository.dart';

void main() {
  late MockPetRepository mockRepository;
  late UpdatePet updatePet;

  setUp(() {
    mockRepository = MockPetRepository();
    updatePet = UpdatePet(mockRepository);
  });

  final testPet = Pet(
    id: 'test-id-1',
    name: 'Buddy Updated',
    species: 'Dog',
    breed: 'Golden Retriever',
    dateOfBirth: DateTime(2021, 6, 1),
    weight: 32.0,
  );

  test('should update pet via repository', () async {
    when(mockRepository.updatePet(testPet)).thenAnswer((_) async => testPet);

    final result = await updatePet(testPet);

    expect(result, equals(testPet));
    verify(mockRepository.updatePet(testPet)).called(1);
  });
}
