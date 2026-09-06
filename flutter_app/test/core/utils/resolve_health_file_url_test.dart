import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/core/utils/resolve_health_file_url.dart';

void main() {
  group('resolveHealthFileUrl', () {
    test('prefixes private health API path on web', () {
      expect(
        resolveHealthFileUrl(
          '/api/health-files/abc-123',
          apiBaseUrl: '/backend',
        ),
        '/backend/api/health-files/abc-123',
      );
    });

    test('prefixes private health API path on absolute base', () {
      expect(
        resolveHealthFileUrl(
          '/api/health-files/abc-123',
          apiBaseUrl: 'http://localhost:3000/backend',
        ),
        'http://localhost:3000/backend/api/health-files/abc-123',
      );
    });

    test('isPrivateHealthFileUrl detects API paths', () {
      expect(isPrivateHealthFileUrl('/api/health-files/id'), isTrue);
      expect(
        isPrivateHealthFileUrl('/uploads/health_documents/x.jpg'),
        isFalse,
      );
    });
  });
}
