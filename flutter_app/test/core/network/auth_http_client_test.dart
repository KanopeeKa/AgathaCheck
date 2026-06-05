import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:pet_profile_app/core/network/auth_http_client.dart';

void main() {
  group('AuthHttpClient', () {
    test('injects the current access token as a Bearer header', () async {
      String? seenAuth;
      final inner = MockClient((req) async {
        seenAuth = req.headers['Authorization'];
        return http.Response('ok', 200);
      });
      final client = AuthHttpClient(
        inner: inner,
        getAccessToken: () => 'tok1',
        refreshAccessToken: () async => null,
      );

      final res = await client.get(Uri.parse('https://example.com/api'));

      expect(res.statusCode, 200);
      expect(seenAuth, 'Bearer tok1');
    });

    test('does not attempt a refresh when the request succeeds', () async {
      var refreshCalls = 0;
      final inner = MockClient((req) async => http.Response('ok', 200));
      final client = AuthHttpClient(
        inner: inner,
        getAccessToken: () => 'tok',
        refreshAccessToken: () async {
          refreshCalls++;
          return 'new';
        },
      );

      await client.get(Uri.parse('https://example.com/api'));

      expect(refreshCalls, 0);
    });

    test('on 401 refreshes once and retries with the new token', () async {
      final seenTokens = <String?>[];
      var refreshCalls = 0;
      final inner = MockClient((req) async {
        final auth = req.headers['Authorization'];
        seenTokens.add(auth);
        if (auth == 'Bearer old') return http.Response('unauthorized', 401);
        return http.Response('ok', 200);
      });
      final client = AuthHttpClient(
        inner: inner,
        getAccessToken: () => 'old',
        refreshAccessToken: () async {
          refreshCalls++;
          return 'new';
        },
      );

      final res = await client.get(Uri.parse('https://example.com/api'));

      expect(res.statusCode, 200);
      expect(refreshCalls, 1);
      expect(seenTokens, ['Bearer old', 'Bearer new']);
    });

    test('replays the request body on the retry', () async {
      final seenBodies = <String>[];
      final inner = MockClient((req) async {
        seenBodies.add(req.body);
        final ok = req.headers['Authorization'] == 'Bearer new';
        return http.Response(ok ? 'ok' : 'unauthorized', ok ? 200 : 401);
      });
      final client = AuthHttpClient(
        inner: inner,
        getAccessToken: () => 'old',
        refreshAccessToken: () async => 'new',
      );

      await client.post(
        Uri.parse('https://example.com/api'),
        headers: {'Content-Type': 'text/plain'},
        body: 'hello-body',
      );

      expect(seenBodies, ['hello-body', 'hello-body']);
    });

    test('throws SessionExpiredException when the refresh fails', () async {
      final inner = MockClient((req) async => http.Response('unauthorized', 401));
      final client = AuthHttpClient(
        inner: inner,
        getAccessToken: () => 'old',
        refreshAccessToken: () async => null,
      );

      expect(
        () => client.get(Uri.parse('https://example.com/api')),
        throwsA(isA<SessionExpiredException>()),
      );
    });

    test('omits the Authorization header when there is no token', () async {
      var hasAuth = true;
      final inner = MockClient((req) async {
        hasAuth = req.headers.containsKey('Authorization');
        return http.Response('ok', 200);
      });
      final client = AuthHttpClient(
        inner: inner,
        getAccessToken: () => null,
        refreshAccessToken: () async => null,
      );

      await client.get(Uri.parse('https://example.com/api'));

      expect(hasAuth, isFalse);
    });

    test('replays a multipart request with the refreshed token', () async {
      final seenHeaders = <Map<String, String>>[];
      final seenBodies = <String>[];
      final inner = MockClient((req) async {
        seenHeaders.add(Map<String, String>.of(req.headers));
        seenBodies.add(req.body);
        final ok = req.headers['Authorization'] == 'Bearer new';
        return http.Response('', ok ? 200 : 401);
      });
      final client = AuthHttpClient(
        inner: inner,
        getAccessToken: () => 'old',
        refreshAccessToken: () async => 'new',
      );

      final request = http.MultipartRequest(
          'POST', Uri.parse('https://example.com/api/photos'))
        ..files.add(
            http.MultipartFile.fromBytes('photo', [1, 2, 3, 4], filename: 'p.png'))
        ..fields['caption'] = 'hi';

      final streamed = await client.send(request);

      expect(streamed.statusCode, 200);
      expect(seenHeaders.length, 2);
      // Both attempts kept a valid multipart content-type with a boundary.
      expect(seenHeaders[0]['content-type'],
          contains('multipart/form-data; boundary='));
      expect(seenHeaders[1]['content-type'],
          contains('multipart/form-data; boundary='));
      // Retry used the refreshed token and preserved the field/file payload.
      expect(seenBodies[1], contains('caption'));
      expect(seenBodies[1], contains('filename="p.png"'));
    });
  });
}
