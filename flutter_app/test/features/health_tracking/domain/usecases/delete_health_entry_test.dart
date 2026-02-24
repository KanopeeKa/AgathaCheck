import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:pet_profile_app/features/health_tracking/domain/usecases/delete_health_entry.dart';

import 'get_health_entries_test.mocks.dart';

void main() {
  late MockHealthRepository mockRepository;
  late DeleteHealthEntry useCase;

  setUp(() {
    mockRepository = MockHealthRepository();
    useCase = DeleteHealthEntry(mockRepository);
  });

  test('delegates to repository.deleteEntry', () async {
    when(mockRepository.deleteEntry('entry-1'))
        .thenAnswer((_) async {});

    await useCase('entry-1');
    verify(mockRepository.deleteEntry('entry-1')).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('propagates repository exceptions', () async {
    when(mockRepository.deleteEntry('entry-1'))
        .thenThrow(Exception('Not found'));

    expect(() => useCase('entry-1'), throwsException);
  });
}
