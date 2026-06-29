import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_issue_model.dart';

void main() {
  group('HealthIssueModel', () {
    final fullJson = {
      'id': 'hi-1',
      'pet_id': 'pet-1',
      'title': 'Allergy',
      'description': 'Pollen',
      'start_date': '2025-03-01',
      'end_date': '2025-06-15',
    };

    test('fromJson parses calendar dates', () {
      final model = HealthIssueModel.fromJson(fullJson);
      expect(model.startDate!.year, 2025);
      expect(model.startDate!.month, 3);
      expect(model.startDate!.day, 1);
      expect(model.endDate!.day, 15);
    });

    test('fromJson uses date portion of legacy UTC timestamps', () {
      final model = HealthIssueModel.fromJson({
        ...fullJson,
        'start_date': '2025-03-01T00:00:00.000Z',
        'end_date': '2025-06-15T00:00:00.000Z',
      });
      expect(model.startDate!.day, 1);
      expect(model.endDate!.day, 15);
    });

    test('toJson serializes calendar dates as date-only', () {
      final model = HealthIssueModel(
        id: 'hi-1',
        petId: 'pet-1',
        title: 'Allergy',
        startDate: DateTime(2025, 3, 1),
        endDate: DateTime(2025, 6, 15),
      );
      final json = model.toJson();
      expect(json['start_date'], '2025-03-01');
      expect(json['end_date'], '2025-06-15');
      expect(json['start_date'], isNot(contains('T')));
    });

    test('round-trip preserves calendar dates', () {
      final original = HealthIssueModel.fromJson(fullJson);
      final restored = HealthIssueModel.fromJson(original.toJson());
      expect(restored.startDate!.day, 1);
      expect(restored.endDate!.day, 15);
    });
  });
}
