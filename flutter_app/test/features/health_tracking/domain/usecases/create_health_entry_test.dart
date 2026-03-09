import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/usecases/create_health_entry.dart';

import '../../../../helpers/mock_health_repository.dart';

void main() {
  late MockHealthRepository mockRepository;
  late CreateHealthEntry useCase;

  setUp(() {
    mockRepository = MockHealthRepository();
    useCase = CreateHealthEntry(mockRepository);
  });

  final testEntry = HealthEntry(
    id: '1',
    petId: 'pet-1',
    name: 'Heartgard',
    type: HealthEntryType.medication,
    frequency: HealthFrequency.monthly,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime(2025, 2, 1),
  );

  test('delegates to repository.createEntry', () async {
    when(mockRepository.createEntry(testEntry))
        .thenAnswer((_) async => testEntry);

    final result = await useCase(testEntry);
    expect(result, testEntry);
    verify(mockRepository.createEntry(testEntry)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('returns the created entry from repository', () async {
    final createdEntry = testEntry.copyWith(id: 'new-id');
    when(mockRepository.createEntry(testEntry))
        .thenAnswer((_) async => createdEntry);

    final result = await useCase(testEntry);
    expect(result.id, 'new-id');
  });

  test('propagates repository exceptions', () async {
    when(mockRepository.createEntry(testEntry))
        .thenThrow(Exception('Network error'));

    expect(() => useCase(testEntry), throwsException);
  });
}
