import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/health_tracking/domain/entities/health_issue_document.dart';

void main() {
  group('HealthIssueDocument', () {
    test('fromJson parses document fields', () {
      final doc = HealthIssueDocument.fromJson({
        'id': 'doc-1',
        'health_issue_id': 'issue-1',
        'url': 'https://example.com/report.pdf',
        'created_at': '2025-03-01T12:00:00.000Z',
      });

      expect(doc.id, 'doc-1');
      expect(doc.healthIssueId, 'issue-1');
      expect(doc.url, 'https://example.com/report.pdf');
      expect(doc.createdAt, DateTime.parse('2025-03-01T12:00:00.000Z'));
    });

    test('fromJson tolerates missing optional fields', () {
      final doc = HealthIssueDocument.fromJson({});

      expect(doc.id, '');
      expect(doc.healthIssueId, '');
      expect(doc.url, '');
      expect(doc.createdAt, isNull);
    });
  });
}
