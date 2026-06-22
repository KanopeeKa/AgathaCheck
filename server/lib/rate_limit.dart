import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';

/// In-memory fixed-window rate limiter for the sensitive auth endpoints,
/// mirroring `server/config/rateLimit.js` (default 10 requests / 15 min per
/// client IP). Call [checkAuthRateLimit] at the top of a handler; if it returns
/// a non-null [Response], return that 429 immediately.
///
/// This is a single-process in-memory limiter (sufficient for the single
/// cPanel/Passenger Node-or-Dart instance this app deploys to); a multi-instance
/// deployment would need a shared store.

class _Window {
  _Window(this.count, this.resetAt);
  int count;
  final DateTime resetAt;
}

final Map<String, _Window> _buckets = {};

int get _windowMs =>
    int.tryParse(Platform.environment['AUTH_RATE_LIMIT_WINDOW_MS'] ?? '') ??
    15 * 60 * 1000;
int get _limit =>
    int.tryParse(Platform.environment['AUTH_RATE_LIMIT_MAX'] ?? '') ?? 10;

String _clientKey(Request request) {
  final forwarded = request.headers['x-forwarded-for'];
  if (forwarded != null && forwarded.isNotEmpty) {
    return forwarded.split(',').first.trim();
  }
  final info = request.context['shelf.io.connection_info'];
  if (info is HttpConnectionInfo) return info.remoteAddress.address;
  return 'unknown';
}

/// Returns a 429 [Response] when the caller has exceeded the limit, else null.
Response? checkAuthRateLimit(Request request) {
  final now = DateTime.now();
  final key = _clientKey(request);
  final window = _buckets[key];
  if (window == null || now.isAfter(window.resetAt)) {
    _buckets[key] =
        _Window(1, now.add(Duration(milliseconds: _windowMs)));
    return null;
  }
  window.count++;
  if (window.count > _limit) {
    return Response(429,
        body: jsonEncode({'error': 'Too many requests, please try again later.'}),
        headers: {'Content-Type': 'application/json'});
  }
  return null;
}
