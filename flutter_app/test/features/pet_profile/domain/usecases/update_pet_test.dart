import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/repositories/pet_repository.dart';
import 'package:pet_profile_app/features/pet_profile/domain/usecases/update_pet.dart';

@GenerateNiceMocks([MockSpec<PetRepository>()])
import 'update_pet_test.mocks.dart';

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
