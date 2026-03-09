import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';
import 'package:pet_profile_app/features/health_tracking/domain/usecases/get_health_entries.dart';

@GenerateMocks([HealthRepository])
import 'get_health_entries_test.mocks.dart';

void main() {
  late MockHealthRepository mockRepository;
  late GetHealthEntries useCase;

  setUp(() {
    mockRepository = MockHealthRepository();
    useCase = GetHealthEntries(mockRepository);
  });

  final testEntries = [
    HealthEntry(
      id: '1',
      petId: 'pet-1',
      name: 'Heartgard',
      type: HealthEntryType.medication,
      frequency: HealthFrequency.monthly,
      startDate: DateTime(2025, 1, 1),
      nextDueDate: DateTime(2025, 2, 1),
    ),
  ];

  test('returns entries from repository', () async {
    when(mockRepository.getEntries(petId: null, type: null))
        .thenAnswer((_) async => testEntries);

    final result = await useCase();
    expect(result, testEntries);
    verify(mockRepository.getEntries(petId: null, type: null)).called(1);
  });

  test('passes petId filter to repository', () async {
    when(mockRepository.getEntries(
            petId: 'pet-1', type: null))
        .thenAnswer((_) async => testEntries);

    await useCase(petId: 'pet-1');
    verify(mockRepository.getEntries(petId: 'pet-1', type: null))
        .called(1);
  });

  test('passes type filter to repository', () async {
    when(mockRepository.getEntries(
            petId: null, type: HealthEntryType.preventive))
        .thenAnswer((_) async => []);

    final result = await useCase(type: HealthEntryType.preventive);
    expect(result, isEmpty);
  });
}
