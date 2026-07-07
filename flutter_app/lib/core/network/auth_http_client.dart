import 'dart:async';

import 'package:http/http.dart' as http;

/// Thrown when a request returns 401 and the access token could not be
/// refreshed (the refresh token is missing, expired, or rejected). The
/// message is user-facing and tells them how to recover.
class SessionExpiredException implements Exception {
  SessionExpiredException([
    this.message =
        'Your session has expired. Please reload the page and sign in again.',
  ]);

  final String message;

  @override
  String toString() => message;
}

/// An [http.Client] wrapper that transparently keeps requests authenticated.
///
/// On every request it injects the freshest access token as a Bearer header.
/// If the server responds 401, it attempts a single token refresh and, on
/// success, replays the original request once with the new token. If the
/// refresh fails it throws [SessionExpiredException] so callers surface a
/// graceful "please reload and sign in" message instead of a silent failure.
class AuthHttpClient extends http.BaseClient {
  AuthHttpClient({
    required http.Client inner,
    required String? Function() getAccessToken,
    required Future<String?> Function() refreshAccessToken,
  }) : _inner = inner,
       _getAccessToken = getAccessToken,
       _refreshAccessToken = refreshAccessToken;

  final http.Client _inner;
  final String? Function() _getAccessToken;
  final Future<String?> Function() _refreshAccessToken;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Buffer the body so the request can be replayed after a refresh.
    final bodyBytes = await request.finalize().toBytes();

    final response = await _inner.send(
      _rebuild(request, bodyBytes, _getAccessToken()),
    );
    if (response.statusCode != 401) return response;

    // Release the failed response's socket before retrying.
    await response.stream.drain<void>();

    final newToken = await _refreshAccessToken();
    if (newToken == null) {
      throw SessionExpiredException();
    }
    return _inner.send(_rebuild(request, bodyBytes, newToken));
  }

  /// Rebuilds [original] as a fresh, unsent [http.Request] carrying [bodyBytes]
  /// and a Bearer [token] (overriding any Authorization the caller set).
  http.Request _rebuild(
    http.BaseRequest original,
    List<int> bodyBytes,
    String? token,
  ) {
    final req = http.Request(original.method, original.url)
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection
      ..headers.addAll(original.headers)
      ..bodyBytes = bodyBytes;
    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    } else {
      req.headers.remove('Authorization');
    }
    return req;
  }

  @override
  void close() => _inner.close();
}
