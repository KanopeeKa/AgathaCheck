import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/branding/logo_assets.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';

void main() {
  group('LogoAssets', () {
    test('maps guardian to plum and organisation to teal on light surfaces', () {
      expect(LogoAssets.pngFor(AppExperience.guardian), 'assets/logo-plum.png');
      expect(
        LogoAssets.pngFor(AppExperience.organization),
        'assets/logo-teal.png',
      );
      expect(LogoAssets.jpgFor(AppExperience.guardian), 'assets/logo-plum.jpg');
      expect(
        LogoAssets.jpgFor(AppExperience.organization),
        'assets/logo-teal.jpg',
      );
    });

    test('uses light monochrome marks on dark surfaces', () {
      expect(
        LogoAssets.pngFor(AppExperience.guardian, onDarkBackground: true),
        'assets/logo-plum-dark.png',
      );
      expect(
        LogoAssets.pngFor(AppExperience.organization, onDarkBackground: true),
        'assets/logo-guardian-light-teal.png',
      );
      expect(
        LogoAssets.careMarkPng(onDarkBackground: true),
        'assets/branding/agathatrack-care-mark-dark.png',
      );
      expect(
        LogoAssets.careMarkPng(),
        'assets/branding/agathatrack-care-mark-light.png',
      );
    });

    test('guardian shell chrome uses the light plum mark on the plum app bar', () {
      expect(
        LogoAssets.pngForShell(AppExperience.guardian),
        'assets/logo-plum-dark.png',
      );
      expect(
        LogoAssets.pngForShell(AppExperience.organization),
        'assets/logo-teal.png',
      );
    });

    test('detects organisation routes', () {
      expect(
        LogoAssets.experienceForRoute('/o/home'),
        AppExperience.organization,
      );
      expect(
        LogoAssets.experienceForRoute('/organizations/abc'),
        AppExperience.organization,
      );
      expect(LogoAssets.experienceForRoute('/g/home'), AppExperience.guardian);
      expect(LogoAssets.experienceForRoute('/about'), AppExperience.guardian);
    });
  });
}
