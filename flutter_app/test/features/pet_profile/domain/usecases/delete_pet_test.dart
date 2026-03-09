import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pet_profile_app/features/pet_profile/domain/usecases/delete_pet.dart';

import '../../../../helpers/mock_pet_repository.dart';

void main() {
  late MockPetRepository mockRepository;
  late DeletePet deletePet;

  setUp(() {
    mockRepository = MockPetRepository();
    deletePet = DeletePet(mockRepository);
  });

  test('should delete pet via repository', () async {
    when(mockRepository.deletePet('test-id'))
        .thenAnswer((_) async => Future.value());

    await deletePet('test-id');

    verify(mockRepository.deletePet('test-id')).called(1);
  });
}
