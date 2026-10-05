import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_profile_app/core/network/auth_http_client.dart';
import 'package:pet_profile_app/features/health_tracking/data/repositories/health_documents_repository_impl.dart';
import 'package:pet_profile_app/features/health_tracking/domain/failures/health_document_failure.dart';

void main() {
  const baseUrl = 'http://localhost:5000';

  group('HealthDocumentsRepositoryImpl', () {
    test('uploadEntryDocument returns id and url on success', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/health-entries/entry-1/photos');
        return http.Response(
          json.encode({
            'id': 'doc-1',
            'event_id': 'entry-1',
            'photo_path': '/uploads/x.jpg',
          }),
          200,
        );
      });
      final repo = HealthDocumentsRepositoryImpl(
        baseUrl: baseUrl,
        client: client,
      );
      final doc = await repo.uploadEntryDocument(
        'entry-1',
        Uint8List.fromList([1]),
        'x.jpg',
      );
      expect(doc.id, 'doc-1');
      expect(doc.url, '/uploads/x.jpg');
      expect(doc.healthEntryId, 'entry-1');
    });

    test(
      'uploadEntryDocument maps 4xx to HealthDocumentClientFailure',
      () async {
        final client = MockClient(
          (_) async => http.Response('{"error":"nope"}', 403),
        );
        final repo = HealthDocumentsRepositoryImpl(
          baseUrl: baseUrl,
          client: client,
        );
        await expectLater(
          repo.uploadEntryDocument('e1', Uint8List(0), 'a.jpg'),
          throwsA(
            isA<HealthDocumentClientFailure>().having(
              (e) => e.statusCode,
              'statusCode',
              403,
            ),
          ),
        );
      },
    );

    test(
      'uploadEntryDocument maps 5xx to HealthDocumentServerFailure',
      () async {
        final client = MockClient((_) async => http.Response('fail', 502));
        final repo = HealthDocumentsRepositoryImpl(
          baseUrl: baseUrl,
          client: client,
        );
        await expectLater(
          repo.uploadEntryDocument('e1', Uint8List(0), 'a.jpg'),
          throwsA(
            isA<HealthDocumentServerFailure>().having(
              (e) => e.statusCode,
              'statusCode',
              502,
            ),
          ),
        );
      },
    );

    test('uploadEntryDocument maps network errors', () async {
      final client = MockClient(
        (_) async => throw const SocketException('down'),
      );
      final repo = HealthDocumentsRepositoryImpl(
        baseUrl: baseUrl,
        client: client,
      );
      await expectLater(
        repo.uploadEntryDocument('e1', Uint8List(0), 'a.jpg'),
        throwsA(isA<HealthDocumentNetworkFailure>()),
      );
    });

    test('removeEntryDocument succeeds', () async {
      var deleted = false;
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        deleted = true;
        return http.Response('', 200);
      });
      final repo = HealthDocumentsRepositoryImpl(
        baseUrl: baseUrl,
        client: client,
      );
      await repo.removeEntryDocument('entry-1', 'doc-1');
      expect(deleted, isTrue);
    });

    test('removeIssueDocument maps delete failure', () async {
      final client = MockClient(
        (_) async => http.Response('{"error":"gone"}', 404),
      );
      final repo = HealthDocumentsRepositoryImpl(
        baseUrl: baseUrl,
        client: client,
      );
      await expectLater(
        repo.removeIssueDocument('issue-1', 'doc-1'),
        throwsA(isA<HealthDocumentClientFailure>()),
      );
    });

    test(
      '401 refresh replays document upload through AuthHttpClient',
      () async {
        var entryCalls = 0;
        final inner = MockClient((request) async {
          if (request.url.path.contains('/photos')) {
            entryCalls++;
            if (entryCalls == 1) {
              expect(request.headers['Authorization'], 'Bearer stale');
              return http.Response('unauthorized', 401);
            }
            expect(request.headers['Authorization'], 'Bearer new-access');
            return http.Response(
              json.encode({
                'id': 'p2',
                'event_id': 'e1',
                'photo_path': '/ok.jpg',
              }),
              200,
            );
          }
          return http.Response('not found', 404);
        });

        final authClient = AuthHttpClient(
          inner: inner,
          getAccessToken: () => 'stale',
          refreshAccessToken: () async => 'new-access',
        );
        final repo = HealthDocumentsRepositoryImpl(
          baseUrl: baseUrl,
          client: authClient,
        );
        final doc = await repo.uploadEntryDocument(
          'e1',
          Uint8List.fromList([9]),
          'ok.jpg',
        );
        expect(doc.id, 'p2');
        expect(entryCalls, 2);
      },
    );

    test(
      '401 without refresh token surfaces session expired failure',
      () async {
        final inner = MockClient((request) async {
          if (request.url.path.contains('/photos')) {
            return http.Response('unauthorized', 401);
          }
          return http.Response('not found', 404);
        });
        final authClient = AuthHttpClient(
          inner: inner,
          getAccessToken: () => 'stale',
          refreshAccessToken: () async => null,
        );
        final repo = HealthDocumentsRepositoryImpl(
          baseUrl: baseUrl,
          client: authClient,
        );
        await expectLater(
          repo.uploadEntryDocument('e1', Uint8List(0), 'a.jpg'),
          throwsA(isA<HealthDocumentSessionExpiredFailure>()),
        );
      },
    );
  });
}
