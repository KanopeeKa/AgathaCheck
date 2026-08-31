import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/vet/presentation/utils/vet_initials.dart';

void main() {
  group('vetInitialsFromName', () {
    test('uses first and third letters for a single-word clinic name', () {
      expect(vetInitialsFromName('Sevetys'), 'SV');
    });

    test('uses first and last word initials for multi-word names', () {
      expect(vetInitialsFromName('Dr. Smith'), 'DS');
    });

    test('returns question mark for empty input', () {
      expect(vetInitialsFromName('   '), '?');
    });
  });
}
