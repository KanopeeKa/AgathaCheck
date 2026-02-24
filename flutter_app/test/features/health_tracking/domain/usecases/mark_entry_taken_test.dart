import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';
import 'package:pet_profile_app/features/health_tracking/domain/usecases/mark_entry_taken.dart';

@GenerateMocks([HealthRepository])
import 'mark_entry_taken_test.mocks.dart';

void main() {
  late MockHealthRepository mockRepository;
  late MarkEntryTaken useCase;

  setUp(() {
    mockRepository = MockHealthRepository();
    useCase = MarkEntryTaken(mockRepository);
  });

  final updatedEntry = HealthEntry(
    id: '1',
    petId: 'pet-1',
    name: 'Heartgard',
    type: HealthEntryType.medication,
    frequency: HealthFrequency.monthly,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime(2025, 3, 1),
  );

  test('marks entry as taken and returns updated entry', () async {
    when(mockRepository.markTaken('1', notes: ''))
        .thenAnswer((_) async => updatedEntry);

    final result = await useCase('1');
    expect(result.nextDueDate, DateTime(2025, 3, 1));
    verify(mockRepository.markTaken('1', notes: '')).called(1);
  });

  test('passes notes to repository', () async {
    when(mockRepository.markTaken('1', notes: 'Given with food'))
        .thenAnswer((_) async => updatedEntry);

    await useCase('1', notes: 'Given with food');
    verify(mockRepository.markTaken('1', notes: 'Given with food')).called(1);
  });
}
