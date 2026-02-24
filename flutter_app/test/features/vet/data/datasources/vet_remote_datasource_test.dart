import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:pet_profile_app/features/vet/data/datasources/vet_remote_datasource.dart';
import 'package:pet_profile_app/features/vet/data/models/vet_model.dart';

void main() {
  const baseUrl = 'http://localhost:5000';

  final testVetJson = {
    'id': '1',
    'name': 'Dr. Smith',
    'phone': '555-1234',
    'email': 'smith@vet.com',
    'website': 'https://drsmith.com',
    'address': '123 Main St',
    'notes': 'Great vet',
    'created_at': '2025-01-01T00:00:00.000',
    'updated_at': '2025-01-02T00:00:00.000',
  };

  group('getAllVets', () {
    test('returns list of VetModel on 200', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), '$baseUrl/api/vets');
        expect(request.method, 'GET');
        return http.Response(json.encode([testVetJson]), 200);
      });

      final datasource =
          VetRemoteDataSourceImpl(baseUrl: baseUrl, client: client);
      final result = await datasource.getAllVets();

      expect(result, hasLength(1));
      expect(result.first.name, 'Dr. Smith');
      expect(result.first.id, '1');
    });

    test('returns empty list on 200 with empty array', () async {
      final client = MockClient((request) async {
        return http.Response(json.encode([]), 200);
      });

      final datasource =
          VetRemoteDataSourceImpl(baseUrl: baseUrl, client: client);
      final result = await datasource.getAllVets();

      expect(result, isEmpty);
    });

    test('throws on 400 error with JSON body', () async {
      final client = MockClient((request) async {
        return http.Response(
            json.encode({'error': 'Bad request'}), 400);
      });

      final datasource =
          VetRemoteDataSourceImpl(baseUrl: baseUrl, client: client);

      expect(
        () => datasource.getAllVets(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Bad request'))),
      );
    });

    test('throws on 500 error with non-JSON body', () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final datasource =
          VetRemoteDataSourceImpl(baseUrl: baseUrl, client: client);

      expect(
        () => datasource.getAllVets(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('HTTP 500'))),
      );
    });
  });

  group('getVet', () {
    test('returns VetModel on 200', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), '$baseUrl/api/vets/1');
        return http.Response(json.encode(testVetJson), 200);
      });

      final datasource =
          VetRemoteDataSourceImpl(baseUrl: baseUrl, client: client);
      final result = await datasource.getVet('1');

      expect(result, isNotNull);
      expect(result!.name, 'Dr. Smith');
      expect(result.phone, '555-1234');
    });

    test('returns null on 404', () async {
      final client = MockClient((request) async {
        return http.Response('Not found', 404);
      });

      final datasource =
          VetRemoteDataSourceImpl(baseUrl: baseUrl, client: client);
      final result = await datasource.getVet('missing');

      expect(result, isNull);
    });

    test('throws on 400 error', () async {
      final client = MockClient((request) async {
        return http.Response(
            json.encode({'error': 'Invalid ID'}), 400);
      });

      final datasource =
          VetRemoteDataSourceImpl(baseUrl: baseUrl, client: client);

      expect(
        () => datasource.getVet('bad-id'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Invalid ID'))),
      );
    });
  });

  group('createVet', () {
    test('sends POST and returns created VetModel', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), '$baseUrl/api/vets');
        expect(request.method, 'POST');
        expect(request.headers['Content-Type'], 'application/json');
        final body = json.decode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'Dr. Smith');
        return http.Response(json.encode(testVetJson), 200);
      });

      final datasource =
          VetRemoteDataSourceImpl(baseUrl: baseUrl, client: client);
      final vet = VetModel.fromJson(testVetJson);
      final result = await datasource.createVet(vet);

      expect(result.name, 'Dr. Smith');
      expect(result.id, '1');
    });

    test('throws on 400 error', () async {
      final client = MockClient((request) async {
        return http.Response(
            json.encode({'error': 'Name required'}), 400);
      });

      final datasource =
          VetRemoteDataSourceImpl(baseUrl: baseUrl, client: client);
      final vet = VetModel.fromJson(testVetJson);

      expect(
        () => datasource.createVet(vet),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Name required'))),
      );
    });
  });

  group('updateVet', () {
    test('sends PUT and returns updated VetModel', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), '$baseUrl/api/vets/1');
        expect(request.method, 'PUT');
        expect(request.headers['Content-Type'], 'application/json');
        return http.Response(json.encode(testVetJson), 200);
      });

      final datasource =
          VetRemoteDataSourceImpl(baseUrl: baseUrl, client: client);
      final vet = VetModel.fromJson(testVetJson);
      final result = await datasource.updateVet(vet);

      expect(result.name, 'Dr. Smith');
    });

    test('throws on 400 error', () async {
      final client = MockClient((request) async {
        return http.Response(
            json.encode({'error': 'Update failed'}), 400);
      });

      final datasource =
          VetRemoteDataSourceImpl(baseUrl: baseUrl, client: client);
      final vet = VetModel.fromJson(testVetJson);

      expect(
        () => datasource.updateVet(vet),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Update failed'))),
      );
    });
  });

  group('deleteVet', () {
    test('sends DELETE request', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), '$baseUrl/api/vets/1');
        expect(request.method, 'DELETE');
        return http.Response('', 200);
      });

      final datasource =
          VetRemoteDataSourceImpl(baseUrl: baseUrl, client: client);
      await datasource.deleteVet('1');
    });

    test('throws on 400 error', () async {
      final client = MockClient((request) async {
        return http.Response(
            json.encode({'error': 'Cannot delete'}), 400);
      });

      final datasource =
          VetRemoteDataSourceImpl(baseUrl: baseUrl, client: client);

      expect(
        () => datasource.deleteVet('1'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Cannot delete'))),
      );
    });
  });

  group('_checkResponse', () {
    test('throws with Unknown error when JSON has no error field', () async {
      final client = MockClient((request) async {
        return http.Response(json.encode({'status': 'fail'}), 400);
      });

      final datasource =
          VetRemoteDataSourceImpl(baseUrl: baseUrl, client: client);

      expect(
        () => datasource.getAllVets(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Unknown error'))),
      );
    });
  });
}
