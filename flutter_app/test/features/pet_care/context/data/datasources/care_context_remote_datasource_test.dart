import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:pet_profile_app/features/pet_care/context/data/datasources/care_context_remote_datasource.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/carer_candidate.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/planned_absence.dart';

void main() {
  const baseUrl = 'http://localhost:5000';

  group('fetchCarerCandidates', () {
    test(
      'GETs /api/pets/:id/carer-candidates and decodes candidates',
      () async {
        String? requestedMethod;
        String? requestedUrl;

        final client = MockClient((request) async {
          requestedMethod = request.method;
          requestedUrl = request.url.toString();
          return http.Response(
            json.encode([
              {'user_id': 'user-2', 'display_name': 'Sarah M.'},
              {'user_id': 'user-3', 'display_name': 'Tom B.'},
            ]),
            200,
          );
        });

        final datasource = CareContextRemoteDataSource(
          baseUrl: baseUrl,
          client: client,
        );
        final result = await datasource.fetchCarerCandidates('pet-1');

        expect(requestedMethod, 'GET');
        expect(requestedUrl, '$baseUrl/api/pets/pet-1/carer-candidates');
        expect(result, hasLength(2));
        expect(result[0].userId, 'user-2');
        expect(result[0].displayName, 'Sarah M.');
        expect(result[1].userId, 'user-3');
        expect(result[1].displayName, 'Tom B.');
      },
    );

    test('returns empty list on 200 with empty array', () async {
      final client = MockClient(
        (request) async => http.Response(json.encode([]), 200),
      );

      final datasource = CareContextRemoteDataSource(
        baseUrl: baseUrl,
        client: client,
      );
      final result = await datasource.fetchCarerCandidates('pet-1');

      expect(result, isEmpty);
    });

    test('throws CareContextApiException with status on 403', () async {
      final client = MockClient(
        (request) async =>
            http.Response(json.encode({'error': 'Forbidden'}), 403),
      );

      final datasource = CareContextRemoteDataSource(
        baseUrl: baseUrl,
        client: client,
      );

      expect(
        () => datasource.fetchCarerCandidates('pet-1'),
        throwsA(
          isA<CareContextApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
    });

    test('sends Authorization header when token is set', () async {
      String? authHeader;

      final client = MockClient((request) async {
        authHeader = request.headers['Authorization'];
        return http.Response(json.encode([]), 200);
      });

      final datasource = CareContextRemoteDataSource(
        baseUrl: baseUrl,
        client: client,
      )..authToken = 'test-token';

      await datasource.fetchCarerCandidates('pet-1');

      expect(authHeader, 'Bearer test-token');
    });
  });

  group('updatePetCarers', () {
    final absenceJson = {
      'id': 'abs-1',
      'user_id': 'user-1',
      'starts_on': '2026-10-01',
      'ends_on': '2026-10-05',
      'provenance': 'user_declared',
      'status': 'active',
      'pet_carers': [
        {
          'pet_id': 'pet-1',
          'carer_kind': 'shared_user',
          'carer_user_id': 'user-2',
          'carer_name': 'Sarah M.',
        },
      ],
    };

    test('PATCHes /api/planned-absences/:id with pet_carers body', () async {
      String? requestedMethod;
      String? requestedUrl;
      String? contentType;
      Map<String, dynamic>? sentBody;

      final client = MockClient((request) async {
        requestedMethod = request.method;
        requestedUrl = request.url.toString();
        contentType = request.headers['Content-Type'];
        sentBody = json.decode(request.body) as Map<String, dynamic>;
        return http.Response(json.encode({'absence': absenceJson}), 200);
      });

      final datasource = CareContextRemoteDataSource(
        baseUrl: baseUrl,
        client: client,
      );
      final result = await datasource.updatePetCarers(
        absenceId: 'abs-1',
        petCarers: [
          {
            'pet_id': 'pet-1',
            'carer_kind': 'shared_user',
            'carer_user_id': 'user-2',
          },
        ],
      );

      expect(requestedMethod, 'PATCH');
      expect(requestedUrl, '$baseUrl/api/planned-absences/abs-1');
      expect(contentType, 'application/json');
      expect(sentBody, {
        'pet_carers': [
          {
            'pet_id': 'pet-1',
            'carer_kind': 'shared_user',
            'carer_user_id': 'user-2',
          },
        ],
      });
      expect(result, isA<PlannedAbsence>());
      expect(result.id, 'abs-1');
      expect(result.petCarers.single.carerName, 'Sarah M.');
    });

    test('unwraps absence when response body has no `absence` key', () async {
      final client = MockClient(
        (request) async => http.Response(json.encode(absenceJson), 200),
      );

      final datasource = CareContextRemoteDataSource(
        baseUrl: baseUrl,
        client: client,
      );
      final result = await datasource.updatePetCarers(
        absenceId: 'abs-1',
        petCarers: [
          {'pet_id': 'pet-1', 'carer_kind': null},
        ],
      );

      expect(result.id, 'abs-1');
    });

    test(
      'throws CareContextApiException with 403 on forbidden carer',
      () async {
        final client = MockClient(
          (request) async =>
              http.Response(json.encode({'error': 'Forbidden'}), 403),
        );

        final datasource = CareContextRemoteDataSource(
          baseUrl: baseUrl,
          client: client,
        );

        expect(
          () => datasource.updatePetCarers(
            absenceId: 'abs-1',
            petCarers: [
              {
                'pet_id': 'pet-1',
                'carer_kind': 'shared_user',
                'carer_user_id': 'user-2',
              },
            ],
          ),
          throwsA(
            isA<CareContextApiException>().having(
              (e) => e.statusCode,
              'statusCode',
              403,
            ),
          ),
        );
      },
    );

    test(
      'throws CareContextApiException with 400 on cancelled absence',
      () async {
        final client = MockClient(
          (request) async => http.Response(
            json.encode({'error': 'Cannot edit a cancelled absence'}),
            400,
          ),
        );

        final datasource = CareContextRemoteDataSource(
          baseUrl: baseUrl,
          client: client,
        );

        expect(
          () => datasource.updatePetCarers(
            absenceId: 'abs-1',
            petCarers: [
              {'pet_id': 'pet-1', 'carer_kind': null},
            ],
          ),
          throwsA(
            isA<CareContextApiException>().having(
              (e) => e.statusCode,
              'statusCode',
              400,
            ),
          ),
        );
      },
    );
  });
}
