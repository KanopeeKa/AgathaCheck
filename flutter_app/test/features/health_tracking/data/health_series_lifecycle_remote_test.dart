import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_profile_app/features/health_tracking/data/datasources/health_series_lifecycle_remote.dart';
import 'package:pet_profile_app/features/health_tracking/data/datasources/health_remote_response.dart';

void main() {
  test('pauseCareItemRemote sends structured postpone body', () async {
    late String body;
    final client = MockClient((request) async {
      body = request.body;
      return http.Response(
        json.encode({
          'entry': {
            'id': 'e1',
            'pet_id': 'p1',
            'name': 'Flea',
            'type': 'medication',
            'frequency': 'monthly',
            'start_date': '2026-06-01',
            'status': 'paused',
            'as_of': {'date': '2026-06-01', 'time': '09:00', 'timezone': 'UTC'},
            'open_occurrences': [],
          },
        }),
        200,
      );
    });

    await pauseCareItemRemote(
      client: client,
      baseUrl: 'http://localhost:3000/backend',
      headers: {'Content-Type': 'application/json'},
      checkResponse: checkHealthRemoteResponse,
      entryId: 'e1',
      until: DateTime(2026, 6, 20),
    );

    expect(json.decode(body), {'reason': 'pause', 'until': '2026-06-20'});
  });

  test('resumeCareItemRemote sends resume date', () async {
    late String body;
    final client = MockClient((request) async {
      body = request.body;
      return http.Response(
        json.encode({
          'entry': {
            'id': 'e1',
            'pet_id': 'p1',
            'name': 'Flea',
            'type': 'medication',
            'frequency': 'monthly',
            'start_date': '2026-06-01',
            'status': 'active',
            'as_of': {'date': '2026-06-01', 'time': '09:00', 'timezone': 'UTC'},
            'open_occurrences': [
              {
                'id': 'o1',
                'scheduled_date': '2026-08-03',
                'status': 'coming_up',
                'origin': 'planned',
              },
            ],
          },
        }),
        200,
      );
    });

    await resumeCareItemRemote(
      client: client,
      baseUrl: 'http://localhost:3000/backend',
      headers: {'Content-Type': 'application/json'},
      checkResponse: checkHealthRemoteResponse,
      entryId: 'e1',
      resumeOn: DateTime(2026, 8, 3),
    );

    expect(json.decode(body), {'date': '2026-08-03'});
  });
}
