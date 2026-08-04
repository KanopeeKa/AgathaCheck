import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/utils/org_screen_theme.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_card.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  const organizationWithPhoto = Organization(
    id: 'org-1',
    name: 'Rescue Hearts',
    type: OrganizationType.charity,
    memberCount: 3,
    petCount: 12,
    photoUrl: '/uploads/org_photos/hero.jpg',
  );

  const organizationWithoutPhoto = Organization(
    id: 'org-2',
    name: 'Quiet Shelter',
    type: OrganizationType.charity,
    memberCount: 1,
    petCount: 0,
  );

  testWidgets('org card uses surface fill without elevation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: orgThemed(
            child: Scaffold(body: OrgCard(organization: organizationWithPhoto)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, orgListCardColor());
    expect(card.elevation, 0);
    expect((card.shape as RoundedRectangleBorder).side, BorderSide.none);
  });

  testWidgets('org card uses pet-style tile height', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: orgThemed(
            child: Scaffold(body: OrgCard(organization: organizationWithPhoto)),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.height == OrgCard.tileHeight,
      ),
      findsOneWidget,
    );
  });

  testWidgets('org card without hero photo uses solid organization teal', (
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
              body: OrgCard(organization: organizationWithoutPhoto),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tealHero = find.byWidgetPredicate(
      (widget) =>
          widget is ColoredBox &&
          widget.color == AppColorTokens.organizationLight,
    );
    expect(tealHero, findsOneWidget);
    expect(find.text('Quiet Shelter'), findsOneWidget);
  });
}
