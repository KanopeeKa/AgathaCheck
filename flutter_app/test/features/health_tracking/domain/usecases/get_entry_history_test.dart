import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:pet_profile_app/features/health_tracking/domain/entities/health_history_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/usecases/get_entry_history.dart';

import '../../../../helpers/mock_health_repository.dart';

void main() {
  late MockHealthRepository mockRepository;
  late GetEntryHistory useCase;

  setUp(() {
    mockRepository = MockHealthRepository();
    useCase = GetEntryHistory(mockRepository);
  });

  final testHistory = [
    HealthHistoryEntry(
      id: 'h1',
      entryId: 'entry-1',
      takenAt: DateTime(2025, 1, 15),
      notes: 'Administered successfully',
    ),
    HealthHistoryEntry(
      id: 'h2',
      entryId: 'entry-1',
      takenAt: DateTime(2025, 2, 15),
    ),
  ];

  test('delegates to repository.getHistory', () async {
    when(mockRepository.getHistory('entry-1'))
        .thenAnswer((_) async => testHistory);

    final result = await useCase('entry-1');
    expect(result, testHistory);
    expect(result.length, 2);
    verify(mockRepository.getHistory('entry-1')).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('returns empty list when no history exists', () async {
    when(mockRepository.getHistory('entry-2'))
        .thenAnswer((_) async => []);

    final result = await useCase('entry-2');
    expect(result, isEmpty);
  });

  test('propagates repository exceptions', () async {
    when(mockRepository.getHistory('entry-1'))
        .thenThrow(Exception('Network error'));

    expect(() => useCase('entry-1'), throwsException);
  });
}
