import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/vet/presentation/utils/care_team_initials.dart';

void main() {
  group('careTeamInitialsFromName', () {
    test('uses first two letters for a single-word clinic name', () {
      expect(careTeamInitialsFromName('Sevetys'), 'SV');
    });

    test('uses first letters of first two significant words', () {
      expect(careTeamInitialsFromName('Happy Paws Clinic'), 'HP');
      expect(careTeamInitialsFromName('Bergerac Veterinary Centre'), 'BV');
    });

    test('handles doctor-style names', () {
      expect(careTeamInitialsFromName('Dr. Avery'), 'AV');
    });

    test('returns question mark for empty input', () {
      expect(careTeamInitialsFromName(''), '?');
      expect(careTeamInitialsFromName('   '), '?');
    });
  });
}
