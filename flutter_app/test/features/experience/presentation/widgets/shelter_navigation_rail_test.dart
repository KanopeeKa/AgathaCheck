import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pet_profile_app/core/widgets/app_logo_title.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/config/shelter_primary_destinations.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/shelter_navigation_rail.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

const _pinnedOrg = ShelterPinnedOrganization(
  id: 'org-pin-1',
  name: 'Happy Tails',
);

void main() {
  testWidgets('rail header shows logo-only brand mark', (tester) async {
    await tester.binding.setSurfaceSize(const Size(720, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith((ref) => FakeAuthNotifier())],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(720, 900)),
            child: const ShelterNavigationRail(currentLocation: '/o/orgs'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppLogoTitle), findsOneWidget);
    expect(find.text('AgathaTrack'), findsNothing);
    expect(find.bySemanticsLabel('AgathaTrack'), findsOneWidget);
    expect(find.byKey(const Key('shelter_navigation_rail')), findsOneWidget);
  });

  testWidgets('rail shows pinned org destination when pin is set', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(720, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith((ref) => FakeAuthNotifier())],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(720, 900)),
            child: ShelterNavigationRail(
              currentLocation: '/o/orgs/org-pin-1',
              pinnedOrg: _pinnedOrg,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Happy Tails'), findsWidgets);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Discover Organisations'), findsWidgets);
    expect(find.text('Account'), findsWidgets);
  });
}
