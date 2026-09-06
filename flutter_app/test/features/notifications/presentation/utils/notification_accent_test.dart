import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/theme/experience_colors.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/notification_scope.dart';
import 'package:pet_profile_app/features/notifications/presentation/utils/notification_accent.dart';

void main() {
  testWidgets('guardian scope uses plum accent tokens', (tester) async {
    late NotificationAccent accent;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            accent = resolveNotificationAccent(
              context,
              NotificationScope.guardian,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final xp = ExperienceColors.light;
    expect(accent.primary, xp.petCarePrimary);
    expect(accent.onPrimary, xp.guardianOnPrimary);
    expect(accent.unreadSurface, xp.guardianLight.withAlpha(120));
    expect(accent.isOrganization, isFalse);
  });

  testWidgets('organization scope uses green accent tokens', (tester) async {
    late NotificationAccent accent;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            accent = resolveNotificationAccent(
              context,
              NotificationScope.organization,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final xp = ExperienceColors.light;
    expect(accent.primary, xp.organizationPrimary);
    expect(accent.onPrimary, xp.organizationOnPrimary);
    expect(accent.unreadSurface, xp.organizationLight.withAlpha(120));
    expect(accent.isOrganization, isTrue);
  });
}
