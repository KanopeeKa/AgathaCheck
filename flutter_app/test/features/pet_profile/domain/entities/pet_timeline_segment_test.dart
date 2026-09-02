import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_timeline_segment.dart';

void main() {
  group('PetTimelineSegment', () {
    test('fromJson parses fostering session segment', () {
      final segment = PetTimelineSegment.fromJson({
        'kind': 'fostering_session',
        'id': 'fp-1',
        'start_date': '2025-06-01',
        'end_date': '2025-08-31',
        'foster_name': 'Frank',
      });

      expect(segment.isFosteringSession, isTrue);
      expect(segment.fosterName, 'Frank');
      expect(segment.startDate, '2025-06-01');
    });

    test('fromJson parses gap placeholder', () {
      final segment = PetTimelineSegment.fromJson({
        'kind': 'gap',
        'id': 'gap-1',
        'start_date': '2024-01-01',
        'end_date': '2024-06-01',
        'fillable': true,
      });

      expect(segment.isGap, isTrue);
      expect(segment.fillable, isTrue);
    });

    test('dateOfBirth and joinedAgatha factories set stable kinds', () {
      final dob = PetTimelineSegment.dateOfBirth(DateTime(2019, 5, 20));
      final joined = PetTimelineSegment.joinedAgatha(
        createdAt: DateTime(2024, 2, 1),
        primaryHolderName: 'Alex',
      );

      expect(dob.isDateOfBirth, isTrue);
      expect(dob.id, 'date_of_birth');
      expect(dob.startDate, '2019-05-20');
      expect(joined.isJoinedAgatha, isTrue);
      expect(joined.primaryHolderName, 'Alex');
      expect(joined.startDate, '2024-02-01');
    });
  });
}
