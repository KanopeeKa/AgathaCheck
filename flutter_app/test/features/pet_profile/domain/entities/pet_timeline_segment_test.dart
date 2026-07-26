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
  });
}
