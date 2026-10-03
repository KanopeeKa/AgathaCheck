import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CP-1 (D-CIE-032): no "dose" / "doses" in any EN or FR string. The
/// allowlist is empty on purpose.
void main() {
  for (final path in ['lib/l10n/app_en.arb', 'lib/l10n/app_fr.arb']) {
    test('$path has no "dose" copy', () {
      final arb =
          json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final offenders = <String>[
        for (final e in arb.entries)
          if (!e.key.startsWith('@') &&
              e.value is String &&
              RegExp(r'\bdoses?\b', caseSensitive: false).hasMatch(e.value))
            e.key,
      ];
      expect(offenders, isEmpty);
    });
  }
}
