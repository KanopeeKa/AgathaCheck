import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/usecases/update_health_entry.dart';

import 'get_health_entries_test.mocks.dart';

void main() {
  late MockHealthRepository mockRepository;
  late UpdateHealthEntry useCase;

  setUp(() {
    mockRepository = MockHealthRepository();
    useCase = UpdateHealthEntry(mockRepository);
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

  test('delegates to repository.updateEntry', () async {
    when(mockRepository.updateEntry(testEntry))
        .thenAnswer((_) async => testEntry);

    final result = await useCase(testEntry);
    expect(result, testEntry);
    verify(mockRepository.updateEntry(testEntry)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('returns the updated entry from repository', () async {
    final updatedEntry = testEntry.copyWith(name: 'Updated Name');
    when(mockRepository.updateEntry(testEntry))
        .thenAnswer((_) async => updatedEntry);

    final result = await useCase(testEntry);
    expect(result.name, 'Updated Name');
  });

  test('propagates repository exceptions', () async {
    when(mockRepository.updateEntry(testEntry))
        .thenThrow(Exception('Server error'));

    expect(() => useCase(testEntry), throwsException);
  });
}
