import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pet_profile_app/features/vet/domain/usecases/delete_vet.dart';

import '../../../../helpers/mock_vet_repository.dart';

void main() {
  late MockVetRepository mockRepository;
  late DeleteVet deleteVet;

  setUp(() {
    mockRepository = MockVetRepository();
    deleteVet = DeleteVet(mockRepository);
  });

  const testId = 'vet-1';

  test('should delete vet via repository', () async {
    when(mockRepository.deleteVet(testId)).thenAnswer((_) async {});

    await deleteVet(testId);

    verify(mockRepository.deleteVet(testId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should propagate repository exceptions', () async {
    when(mockRepository.deleteVet(testId))
        .thenThrow(Exception('Network error'));

    expect(() => deleteVet(testId), throwsException);
  });
}
