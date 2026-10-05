import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// H.1-4: only [AuthService] in the auth data layer may call the refresh endpoint.
void main() {
  final flutterRoot =
      Directory(p.join(Directory.current.path, 'lib')).existsSync()
      ? Directory.current.path
      : p.join(Directory.current.path, 'flutter_app');
  final libRoot = p.join(flutterRoot, 'lib');

  const allowedRelativePaths = {
    'features/auth/data/auth_service.dart',
  };

  final refreshPatterns = <RegExp>[
    RegExp(r'/api/auth/refresh'),
  ];

  test('refresh endpoint is only referenced from AuthService transport', () {
    final violations = <String>[];
    final libDir = Directory(libRoot);
    expect(libDir.existsSync(), isTrue, reason: 'lib root at $libRoot');

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final relative = p
          .relative(entity.path, from: libRoot)
          .replaceAll('\\', '/');
      if (allowedRelativePaths.contains(relative)) continue;

      final content = entity.readAsStringSync();
      for (final pattern in refreshPatterns) {
        if (pattern.hasMatch(content)) {
          violations.add('$relative: ${pattern.pattern}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Route token refresh through AuthHttpClient / AuthRepository only:\n'
          '${violations.join('\n')}',
    );
  });
}
