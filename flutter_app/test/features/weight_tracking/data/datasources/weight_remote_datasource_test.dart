import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:pet_profile_app/features/weight_tracking/data/datasources/weight_remote_datasource.dart';
import 'package:pet_profile_app/features/weight_tracking/data/models/weight_entry_model.dart';

void main() {
  const baseUrl = 'http://localhost:5000';
  const token = 'test-jwt-token';

  final testEntryJson = {
    'id': 'we-1',
    'pet_id': 'pet-1',
    'weight': 12.5,
    'unit': 'kg',
    'date': '2026-03-26T00:00:00.000',
    'notes': '',
  };

  WeightRemoteDataSourceImpl makeDatasource(http.Client client) {
    return WeightRemoteDataSourceImpl(baseUrl: baseUrl, client: client);
  }

  group('auth header attachment', () {
    test('getEntries sends Authorization bearer header and pet_id query',
        () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer $token');
        expect(request.url.queryParameters['pet_id'], 'pet-1');
        return http.Response(json.encode([testEntryJson]), 200);
      });
      final result = await makeDatasource(client).getEntries('pet-1', token);
      expect(result, hasLength(1));
      expect(result.first.weight, 12.5);
    });

    test('createEntry sends Authorization and JSON content type', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer $token');
        expect(request.headers['Content-Type'], contains('application/json'));
        return http.Response(json.encode(testEntryJson), 201);
      });
      final entry = WeightEntryModel.fromJson(testEntryJson);
      await makeDatasource(client).createEntry(entry, token);
    });

    test('deleteEntry sends Authorization bearer header', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response(json.encode({'deleted': true}), 200);
      });
      await makeDatasource(client).deleteEntry('we-1', token);
    });

    test('getLatestWeight returns null on 404', () async {
      final client = MockClient((request) async {
        expect(request.url.path, contains('/api/weight-entries/latest'));
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response(json.encode({'error': 'No weight entries found'}),
            404);
      });
      final result =
          await makeDatasource(client).getLatestWeight('pet-1', token);
      expect(result, isNull);
    });
  });
}
