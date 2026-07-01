import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/family_event.dart';

void main() {
  group('FamilyEvent.fromJson', () {
    test('parses date-only from_date and to_date', () {
      final event = FamilyEvent.fromJson({
        'id': 'fe-1',
        'pet_id': 'pet-1',
        'organization_id': 'org-1',
        'from_date': '2026-06-30',
        'to_date': '2026-07-05',
      });
      expect(event.fromDate.day, 30);
      expect(event.toDate!.day, 5);
    });

    test('uses date portion of legacy UTC timestamps', () {
      final event = FamilyEvent.fromJson({
        'id': 'fe-1',
        'pet_id': 'pet-1',
        'organization_id': 'org-1',
        'from_date': '2026-06-30T00:00:00.000Z',
      });
      expect(event.fromDate.day, 30);
    });

    test('parses space-separated legacy date strings', () {
      final event = FamilyEvent.fromJson({
        'id': 'fe-1',
        'pet_id': 'pet-1',
        'organization_id': 'org-1',
        'from_date': '2026-06-30 00:00:00.000Z',
        'to_date': '2026-07-05 00:00:00.000Z',
      });
      expect(event.fromDate.day, 30);
      expect(event.toDate!.day, 5);
    });
  });
}
