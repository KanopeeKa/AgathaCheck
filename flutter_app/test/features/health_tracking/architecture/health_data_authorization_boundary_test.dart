import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// H.2-2: health data layer must not attach Authorization headers manually.
void main() {
  final flutterRoot =
      Directory(p.join(Directory.current.path, 'lib')).existsSync()
      ? Directory.current.path
      : p.join(Directory.current.path, 'flutter_app');
  final dataRoot = p.join(
    flutterRoot,
    'lib',
    'features',
    'health_tracking',
    'data',
  );

  test('health data layer does not build Authorization headers', () {
    final violations = <String>[];
    final dataDir = Directory(dataRoot);
    expect(dataDir.existsSync(), isTrue, reason: 'data root at $dataRoot');

    for (final entity in dataDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final relative = p.relative(entity.path, from: dataRoot);
      final content = entity.readAsStringSync();
      if (content.contains("'Authorization'") ||
          content.contains('"Authorization"')) {
        violations.add(relative.replaceAll('\\', '/'));
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use authHttpClientProvider instead of manual bearer headers:\n'
          '${violations.join('\n')}',
    );
  });
}
