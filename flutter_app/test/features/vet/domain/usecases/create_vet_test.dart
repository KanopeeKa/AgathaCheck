import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pet_profile_app/features/vet/domain/entities/vet.dart';
import 'package:pet_profile_app/features/vet/domain/repositories/vet_repository.dart';
import 'package:pet_profile_app/features/vet/domain/usecases/create_vet.dart';

@GenerateNiceMocks([MockSpec<VetRepository>()])
import 'create_vet_test.mocks.dart';

void main() {
  late MockVetRepository mockRepository;
  late CreateVet createVet;

  setUp(() {
    mockRepository = MockVetRepository();
    createVet = CreateVet(mockRepository);
  });

  const testVet = Vet(
    id: 'vet-1',
    name: 'Dr. Smith',
    phone: '555-1234',
    email: 'smith@vet.com',
  );

  test('should create vet via repository', () async {
    when(mockRepository.createVet(testVet)).thenAnswer((_) async => testVet);

    final result = await createVet(testVet);

    expect(result, equals(testVet));
    verify(mockRepository.createVet(testVet)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should propagate repository exceptions', () async {
    when(mockRepository.createVet(testVet))
        .thenThrow(Exception('Network error'));

    expect(() => createVet(testVet), throwsException);
  });
}
