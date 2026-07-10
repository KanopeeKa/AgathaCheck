import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/utils/resolve_static_asset_url.dart';

void main() {
  group('resolveStaticAssetUrl', () {
    test('returns empty string for empty path', () {
      expect(
        resolveStaticAssetUrl('', apiBaseUrl: '/backend'),
        '',
      );
    });

    test('passes through absolute http(s) URLs', () {
      expect(
        resolveStaticAssetUrl(
          'https://cdn.example.com/a.jpg',
          apiBaseUrl: '/backend',
        ),
        'https://cdn.example.com/a.jpg',
      );
      expect(
        resolveStaticAssetUrl(
          'http://localhost:5000/x.png',
          apiBaseUrl: '/backend',
        ),
        'http://localhost:5000/x.png',
      );
    });

    test('upload paths use site root on web (not /backend prefix)', () {
      expect(
        resolveStaticAssetUrl(
          '/uploads/photos/user.jpg',
          apiBaseUrl: '/backend',
        ),
        '/uploads/photos/user.jpg',
      );
    });

    test('upload paths use absolute origin on mobile dev', () {
      expect(
        resolveStaticAssetUrl(
          '/uploads/photos/user.jpg',
          apiBaseUrl: 'http://localhost:5000',
        ),
        'http://localhost:5000/uploads/photos/user.jpg',
      );
    });

    test('non-upload relative paths use api base URL', () {
      expect(
        resolveStaticAssetUrl('/photos/org.jpg', apiBaseUrl: '/backend'),
        '/backend/photos/org.jpg',
      );
      expect(
        resolveStaticAssetUrl('/api/foo', apiBaseUrl: 'http://localhost:5000'),
        'http://localhost:5000/api/foo',
      );
    });
  });
}
