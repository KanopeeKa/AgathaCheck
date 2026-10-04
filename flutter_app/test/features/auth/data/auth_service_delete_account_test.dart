import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_profile_app/features/auth/data/auth_service.dart';

void main() {
  group('AuthService.deleteAccount', () {
    test('returns accepted result for HTTP 202 with operation id', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        return http.Response(
          json.encode({
            'message': 'Account deletion accepted',
            'erasure': {
              'operation_id': 'op-202',
              'status': 'accepted',
              'status_token': 'secret',
            },
          }),
          202,
        );
      });
      final service = AuthService(baseUrl: 'http://test', client: client);

      final result = await service.deleteAccount('token', password: 'pw');

      expect(result.message, 'Account deletion accepted');
      expect(result.operationId, 'op-202');
      expect(result.accepted, isTrue);
    });

    test('returns non-accepted result for HTTP 200 legacy response', () async {
      final client = MockClient((request) async {
        return http.Response(json.encode({'message': 'Account deleted'}), 200);
      });
      final service = AuthService(baseUrl: 'http://test', client: client);

      final result = await service.deleteAccount('token', password: 'pw');

      expect(result.message, 'Account deleted');
      expect(result.operationId, isNull);
      expect(result.accepted, isFalse);
    });

    test('throws on HTTP 400', () async {
      final client = MockClient((request) async {
        return http.Response(
          json.encode({'error': 'Password is incorrect'}),
          400,
        );
      });
      final service = AuthService(baseUrl: 'http://test', client: client);

      expect(
        () => service.deleteAccount('token', password: 'wrong'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
