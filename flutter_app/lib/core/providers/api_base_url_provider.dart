import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiBaseUrlProvider = Provider<String>((ref) {
  if (kIsWeb) {
    // For deployed web app, the backend is at /backend relative to the domain
    return '/backend';
  }
  return 'http://localhost:5000';
});