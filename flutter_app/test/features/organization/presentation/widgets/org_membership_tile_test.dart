import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/utils/org_screen_theme.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_membership_tile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  const organizationWithoutPhoto = Organization(
    id: 'org-1',
    name: 'Rescue Hearts',
    type: OrganizationType.charity,
    memberCount: 3,
    petCount: 12,
  );

  testWidgets('org membership tile uses pet-grid aspect ratio', (tester) async {
    const tileWidth = 160.0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: orgThemed(
            child: Scaffold(
              body: OrgMembershipTile(
                organization: organizationWithoutPhoto,
                tileWidth: tileWidth,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final sizedBox = tester.widget<SizedBox>(
      find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox &&
            widget.width == tileWidth &&
            widget.height == OrgMembershipTile.tileHeightFor(tileWidth),
      ),
    );
    expect(sizedBox.width, tileWidth);
    expect(sizedBox.height, tileWidth * 1.5);
  });

  testWidgets('org membership tile without cover uses organizationPrimary', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: orgThemed(
            child: Scaffold(
              body: OrgMembershipTile(
                organization: organizationWithoutPhoto,
                tileWidth: 160,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final coloredBox = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byKey(const Key('org_membership_tile_org-1')),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(coloredBox.color, AppColorTokens.organizationPrimary);
  });
}
