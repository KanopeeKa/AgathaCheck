import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_image_avatar.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_presentation/org_presentation_hero.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_presentation/org_profile_hero_layout.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  const org = Organization(
    id: 'org-1',
    name: 'Rescue Hearts',
    type: OrganizationType.charity,
    description: 'A caring rescue shelter',
    logoUrl: '/uploads/logo.png',
    photoUrl: '/uploads/cover.png',
  );

  Future<void> pumpHero(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: OrgPresentationHero(
              org: org,
              localizedTypeLabel: 'Charity',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hero places 96px logo overlapping cover with name to the right', (
    tester,
  ) async {
    await pumpHero(tester);

    expect(find.byKey(const Key('org_presentation_hero')), findsOneWidget);
    expect(find.byKey(const Key('org_hero_name')), findsOneWidget);
    expect(find.text('Rescue Hearts'), findsOneWidget);

    final logo = tester.widget<OrgLogoImage>(
      find.byKey(const Key('org_hero_logo')),
    );
    expect(logo.height, OrgProfileHeroLayout.logoHeight);

    final cover = tester.widget<SizedBox>(
      find.descendant(
        of: find.byKey(const Key('org_presentation_hero')),
        matching: find.byType(SizedBox),
      ).first,
    );
    expect(cover.height, OrgProfileHeroLayout.coverHeight);

    final nameBox = tester.getRect(find.byKey(const Key('org_hero_name')));
    final logoBox = tester.getRect(find.byKey(const Key('org_hero_logo')));
    expect(nameBox.left, greaterThan(logoBox.left));
    expect(nameBox.top, greaterThanOrEqualTo(logoBox.top));
  });

  testWidgets('hero shows type badge and raised description', (tester) async {
    await pumpHero(tester);

    expect(find.byKey(const Key('org_hero_type')), findsOneWidget);
    expect(find.text('Charity'), findsOneWidget);
    expect(find.byKey(const Key('org_hero_description')), findsOneWidget);
    expect(find.text('A caring rescue shelter'), findsOneWidget);
  });
}
