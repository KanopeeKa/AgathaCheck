import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pet_profile_app/features/vet/domain/entities/vet.dart';
import 'package:pet_profile_app/features/vet/domain/usecases/update_vet.dart';

import '../../../../helpers/mock_vet_repository.dart';

void main() {
  late MockVetRepository mockRepository;
  late UpdateVet updateVet;

  setUp(() {
    mockRepository = MockVetRepository();
    updateVet = UpdateVet(mockRepository);
  });

  const testVet = Vet(
    id: 'vet-1',
    name: 'Dr. Smith Updated',
    phone: '555-9999',
    email: 'updated@vet.com',
  );

  test('should update vet via repository', () async {
    when(mockRepository.updateVet(testVet)).thenAnswer((_) async => testVet);

    final result = await updateVet(testVet);

    expect(result, equals(testVet));
    verify(mockRepository.updateVet(testVet)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should propagate repository exceptions', () async {
    when(mockRepository.updateVet(testVet))
        .thenThrow(Exception('Network error'));

    expect(() => updateVet(testVet), throwsException);
  });
}
