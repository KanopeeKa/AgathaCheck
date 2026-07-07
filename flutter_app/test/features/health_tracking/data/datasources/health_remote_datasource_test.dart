import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:pet_profile_app/features/health_tracking/data/datasources/health_remote_datasource.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_entry_model.dart';

void main() {
  const baseUrl = 'http://localhost:5000';
  const token = 'test-jwt-token';

  final testEntryJson = {
    'id': 'he-1',
    'pet_id': 'pet-1',
    'name': 'Heartgard',
    'type': 'medication',
    'frequency': 'monthly',
    'start_date': '2025-01-01T00:00:00.000',
    'next_due_date': '2025-02-01T00:00:00.000',
  };

  HealthRemoteDataSourceImpl makeDatasource(
    http.Client client, {
    String? authToken = token,
  }) {
    final ds = HealthRemoteDataSourceImpl(baseUrl: baseUrl, client: client);
    ds.authToken = authToken;
    return ds;
  }

  group('auth header attachment', () {
    test('getEntries sends Authorization bearer header', () async {
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response(json.encode([testEntryJson]), 200);
      });
      await makeDatasource(client).getEntries();
    });

    test('createEntry sends Authorization and JSON content type', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer $token');
        expect(request.headers['Content-Type'], contains('application/json'));
        return http.Response(json.encode(testEntryJson), 200);
      });
      final entry = HealthEntryModel.fromJson(testEntryJson);
      await makeDatasource(client).createEntry(entry);
    });

    test('updateEntry sends Authorization and JSON content type', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.headers['Authorization'], 'Bearer $token');
        expect(request.headers['Content-Type'], contains('application/json'));
        return http.Response(json.encode(testEntryJson), 200);
      });
      final entry = HealthEntryModel.fromJson(testEntryJson);
      await makeDatasource(client).updateEntry(entry);
    });

    test('markTaken sends Authorization bearer header', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          '$baseUrl/api/health-entries/he-1/mark-taken',
        );
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response(json.encode(testEntryJson), 200);
      });
      await makeDatasource(client).markTaken('he-1');
    });

    test('undoComplete sends Authorization bearer header', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          '$baseUrl/api/health-entries/he-1/undo-complete',
        );
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response(json.encode(testEntryJson), 200);
      });
      await makeDatasource(client).undoComplete('he-1');
    });

    test('deleteEntry sends Authorization bearer header', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response('', 200);
      });
      await makeDatasource(client).deleteEntry('he-1');
    });

    test('getEntry sends Authorization bearer header', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response(json.encode(testEntryJson), 200);
      });
      await makeDatasource(client).getEntry('he-1');
    });

    test('getHistory sends Authorization bearer header', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          '$baseUrl/api/health-entries/he-1/history',
        );
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response(json.encode([]), 200);
      });
      await makeDatasource(client).getHistory('he-1');
    });

    test('exportCsv sends Authorization bearer header', () async {
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response('id,name\n', 200);
      });
      await makeDatasource(client).exportCsv();
    });

    test('getPhotos sends Authorization bearer header', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          '$baseUrl/api/health-entries/he-1/photos',
        );
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response(json.encode([]), 200);
      });
      await makeDatasource(client).getPhotos('he-1');
    });

    test(
      'uploadPhoto multipart request carries Authorization header',
      () async {
        final client = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.headers['Authorization'], 'Bearer $token');
          return http.Response(
            json.encode({'id': 1, 'event_id': 'he-1', 'photo_path': '/p.jpg'}),
            200,
          );
        });
        await makeDatasource(
          client,
        ).uploadPhoto('he-1', Uint8List.fromList([1, 2, 3]), 'p.jpg');
      },
    );

    test('deletePhoto sends Authorization bearer header', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response('', 200);
      });
      await makeDatasource(client).deletePhoto('he-1', '1');
    });

    test('omits Authorization header when no token is set', () async {
      final client = MockClient((request) async {
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response(json.encode([testEntryJson]), 200);
      });
      await makeDatasource(client, authToken: null).getEntries();
    });

    test('omits Authorization header when token is empty', () async {
      final client = MockClient((request) async {
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response(json.encode([testEntryJson]), 200);
      });
      await makeDatasource(client, authToken: '').getEntries();
    });
  });
}
