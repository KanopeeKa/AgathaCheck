import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/theme/experience_colors.dart';

void main() {
  group('AppTheme', () {
    test('lightTheme uses guardian plum as default primary', () {
      final theme = AppTheme.lightTheme;
      expect(theme.colorScheme.primary, AppColorTokens.guardianPrimary);
      expect(theme.scaffoldBackgroundColor, AppColorTokens.background);
    });

    test('lightTheme registers ExperienceColors extension', () {
      final ext = AppTheme.lightTheme.extension<ExperienceColors>();
      expect(ext, isNotNull);
      expect(ext!.guardianPrimary, AppColorTokens.guardianPrimary);
      expect(ext.organizationPrimary, AppColorTokens.organizationPrimary);
      expect(ext.success, AppColorTokens.success);
    });

    test('primaryFor selects mode colors', () {
      const ext = ExperienceColors.light;
      expect(
        ext.primaryFor(organization: false),
        AppColorTokens.guardianPrimary,
      );
      expect(
        ext.primaryFor(organization: true),
        AppColorTokens.organizationPrimary,
      );
    });

    test('org legacy aliases map to organisation tokens', () {
      expect(AppTheme.orgIconFg, AppColorTokens.organizationPrimary);
      expect(AppTheme.orgBlue, AppColorTokens.organizationLight);
    });

    test('role and memorial tokens are defined', () {
      expect(AppColorTokens.orgSuperAdminBorder, isNotNull);
      expect(AppColorTokens.petRainbowIconGradient, hasLength(6));
    });
  });
}
