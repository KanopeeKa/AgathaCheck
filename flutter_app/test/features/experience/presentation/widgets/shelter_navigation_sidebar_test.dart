import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/config/shelter_primary_destinations.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/shelter_navigation_sidebar.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

const _pinnedOrg = ShelterPinnedOrganization(
  id: 'org-pin-1',
  name: 'Happy Tails',
);

void main() {
  testWidgets('sidebar renders unpinned destinations', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
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
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(size: Size(1200, 900)),
              child: const ShelterNavigationSidebar(currentLocation: '/o/orgs'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shelter_navigation_sidebar')), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Discover Organisations'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Happy Tails'), findsNothing);
  });

  testWidgets('sidebar renders pinned org destination when pin is set', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
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
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(size: Size(1200, 900)),
              child: ShelterNavigationSidebar(
                currentLocation: '/o/orgs/org-pin-1',
                pinnedOrg: _pinnedOrg,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Happy Tails'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Discover Organisations'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });
}
