import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// G.3-2: presentation widgets must not reach into health data layer directly.
void main() {
  final flutterRoot = Directory(p.join(Directory.current.path, 'lib')).existsSync()
      ? Directory.current.path
      : p.join(Directory.current.path, 'flutter_app');
  final libRoot = p.join(flutterRoot, 'lib');

  final bannedPatterns = <RegExp>[
    RegExp(r'read\s*\(\s*healthRepositoryProvider\s*\)'),
    RegExp(r'read\s*\(\s*healthRemoteDataSourceProvider\s*\)'),
    RegExp(r'read\s*\(\s*healthDataSourceProvider\s*\)'),
    RegExp(r'ref\.invalidate\s*\(\s*healthEntriesNotifierProvider'),
    RegExp(r'ref\.invalidate\s*\(\s*entryOccurrencesProvider'),
    RegExp(r'ref\.invalidate\s*\(\s*entryPastOccurrencesProvider'),
    RegExp(r'ref\.invalidate\s*\(\s*entryHistoryProvider'),
    RegExp(r'ref\.invalidate\s*\(\s*healthEntryPhotosProvider'),
  ];

  bool shouldScan(File file) {
    final normalized = file.path.replaceAll('\\', '/');
    if (normalized.contains('/health_tracking/presentation/widgets/')) {
      return true;
    }
    if (normalized.contains('/health_tracking/presentation/screens/')) {
      return true;
    }
    if (normalized.contains('/pet_care/') &&
        normalized.contains('/presentation/widgets/')) {
      return true;
    }
    return false;
  }

  test('health presentation widgets do not bypass CareScheduleController', () {
    final violations = <String>[];
    final libDir = Directory(libRoot);
    expect(libDir.existsSync(), isTrue, reason: 'lib root at $libRoot');

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (!shouldScan(entity)) continue;
      final relative = p.relative(entity.path, from: libRoot);
      final content = entity.readAsStringSync();
      for (final pattern in bannedPatterns) {
        if (pattern.hasMatch(content)) {
          violations.add('$relative: ${pattern.pattern}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Move data access to CareScheduleController / providers:\n'
          '${violations.join('\n')}',
    );
  });
}
