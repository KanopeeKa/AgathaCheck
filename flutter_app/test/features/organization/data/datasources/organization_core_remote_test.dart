import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_profile_app/features/organization/data/datasources/organization_remote/organization_core_remote.dart';
import 'package:pet_profile_app/features/organization/data/datasources/organization_remote/organization_remote_context.dart';
import 'package:pet_profile_app/features/organization/data/models/organization_model.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';

class _CapturingClient extends http.BaseClient {
  _CapturingClient(this._inner);

  final http.Client _inner;
  http.MultipartFile? capturedFile;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request is http.MultipartRequest && request.files.isNotEmpty) {
      capturedFile = request.files.first;
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

void main() {
  group('contentTypeForOrgImageFilename', () {
    test('maps common extensions to image MIME types', () {
      void expectMime(String filename, String type, String subtype) {
        final mediaType = contentTypeForOrgImageFilename(filename);
        expect(mediaType.type, type);
        expect(mediaType.subtype, subtype);
      }

      expectMime('logo.jpg', 'image', 'jpeg');
      expectMime('cover.JPEG', 'image', 'jpeg');
      expectMime('hero.png', 'image', 'png');
      expectMime('tile.webp', 'image', 'webp');
      expectMime('org_image', 'image', 'jpeg');
    });
  });

  group('OrganizationCoreRemote uploads', () {
    const token = 'tok-abc';
    const orgId = 'org-1';
    const baseUrl = 'http://api.example';

    test('uploadPhoto multipart includes image/jpeg content type', () async {
      final inner = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/organizations/$orgId/photo');
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response(
          json.encode(
            OrganizationModel(
              id: orgId,
              name: 'Test Org',
              type: OrganizationType.professional,
            ).toJson(),
          ),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final client = _CapturingClient(inner);
      addTearDown(client.close);

      final remote = OrganizationCoreRemote(
        OrganizationRemoteContext(baseUrl: baseUrl, client: client),
      );
      await remote.uploadPhoto(
        orgId,
        Uint8List.fromList([0xff, 0xd8, 0xff]),
        'cover.jpg',
        token,
      );

      expect(client.capturedFile?.contentType.type, 'image');
      expect(client.capturedFile?.contentType.subtype, 'jpeg');
    });

    test('surfaces API error message from upload failure', () async {
      final client = MockClient((request) async {
        return http.Response(
          json.encode({'error': 'Only JPG, PNG, and WebP images are allowed'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });
      addTearDown(client.close);

      final remote = OrganizationCoreRemote(
        OrganizationRemoteContext(baseUrl: baseUrl, client: client),
      );

      expect(
        () => remote.uploadLogo(
          orgId,
          Uint8List.fromList([1, 2, 3]),
          'logo.jpg',
          token,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            'Exception: Only JPG, PNG, and WebP images are allowed',
          ),
        ),
      );
    });
  });
}
