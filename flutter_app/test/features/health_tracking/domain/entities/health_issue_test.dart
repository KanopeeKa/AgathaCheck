import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/health_tracking/domain/entities/health_issue.dart';

void main() {
  group('HealthIssue', () {
    const issue = HealthIssue(
      id: 'issue-1',
      petId: 'pet-1',
      title: 'Heart murmur',
      description: 'Grade II',
      eventIds: ['entry-1'],
      startDate: null,
      endDate: null,
    );

    test('copyWith updates fields and can clear dates', () {
      final start = DateTime(2025, 1, 1);
      final updated = issue.copyWith(
        title: 'Updated',
        startDate: start,
        clearEndDate: true,
      );

      expect(updated.title, 'Updated');
      expect(updated.startDate, start);
      expect(updated.endDate, isNull);
      expect(updated.id, issue.id);
    });

    test('equality is based on id', () {
      final other = issue.copyWith(title: 'Different');
      expect(issue, equals(other));
      expect(issue, isNot(equals(issue.copyWith(id: 'other'))));
    });
  });
}
