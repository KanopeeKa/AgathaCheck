import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/vet/presentation/utils/vet_team_initials.dart';

void main() {
  group('vetTeamInitialsFromName', () {
    test('uses first two letters for a single-word clinic name', () {
      expect(vetTeamInitialsFromName('Sevetys'), 'SV');
    });

    test('uses first letters of first two significant words', () {
      expect(vetTeamInitialsFromName('Happy Paws Clinic'), 'HP');
      expect(vetTeamInitialsFromName('Bergerac Veterinary Centre'), 'BV');
    });

    test('handles doctor-style names', () {
      expect(vetTeamInitialsFromName('Dr. Avery'), 'AV');
    });

    test('returns question mark for empty input', () {
      expect(vetTeamInitialsFromName(''), '?');
      expect(vetTeamInitialsFromName('   '), '?');
    });
  });
}
