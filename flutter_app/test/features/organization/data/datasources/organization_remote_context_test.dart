import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pet_profile_app/features/organization/data/datasources/organization_remote/organization_remote_context.dart';

void main() {
  group('OrganizationRemoteContext', () {
    test('headers include JSON content type and bearer token', () {
      final ctx = OrganizationRemoteContext(baseUrl: 'http://test.local');
      expect(
        ctx.headers('tok-123'),
        {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer tok-123',
        },
      );
    });

    test('authOnly omits content type for multipart-friendly calls', () {
      final ctx = OrganizationRemoteContext(baseUrl: 'http://test.local');
      expect(
        ctx.authOnly('tok-123'),
        {'Authorization': 'Bearer tok-123'},
      );
    });

    test('uses injected http client when provided', () {
      final client = http.Client();
      addTearDown(client.close);
      final ctx = OrganizationRemoteContext(
        baseUrl: 'http://api.example',
        client: client,
      );
      expect(ctx.client, same(client));
      expect(ctx.baseUrl, 'http://api.example');
    });
  });
}
