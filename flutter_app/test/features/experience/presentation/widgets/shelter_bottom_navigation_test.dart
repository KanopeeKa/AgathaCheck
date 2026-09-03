import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/config/shelter_primary_destinations.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/shelter_bottom_navigation.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

const _pinnedOrg = ShelterPinnedOrganization(
  id: 'org-pin-1',
  name: 'Happy Tails',
);

void main() {
  group('ShelterPrimaryDestinations', () {
    test('exposes five bottom-bar slots when unpinned', () {
      final slots = ShelterPrimaryDestinations.slots();
      expect(slots, hasLength(5));
      expect(slots[0].kind, ShelterNavSlotKind.destination);
      expect(slots[1].kind, ShelterNavSlotKind.hidden);
      expect(slots[2].kind, ShelterNavSlotKind.spacer);
      expect(slots[3].kind, ShelterNavSlotKind.destination);
      expect(slots[4].kind, ShelterNavSlotKind.destination);
    });

    test('exposes five bottom-bar slots when pinned', () {
      final slots = ShelterPrimaryDestinations.slots(pinnedOrg: _pinnedOrg);
      expect(slots, hasLength(5));
      expect(slots[1].destination?.route, '/o/orgs/org-pin-1');
      expect(slots[1].destination?.labelBuilder, isNotNull);
      expect(slots[2].kind, ShelterNavSlotKind.hidden);
    });

    test('navigable destinations omit spacer slots when unpinned', () {
      final destinations = ShelterPrimaryDestinations.navigableDestinations();
      expect(destinations, hasLength(3));
      expect(destinations.map((d) => d.route), [
        '/o/orgs',
        '/o/orgs/discover',
        '/account',
      ]);
    });

    test('navigable destinations include pinned org when set', () {
      final destinations = ShelterPrimaryDestinations.navigableDestinations(
        pinnedOrg: _pinnedOrg,
      );
      expect(destinations, hasLength(4));
      expect(destinations[1].route, '/o/orgs/org-pin-1');
      expect(destinations[1].labelBuilder, isNotNull);
    });

    test('maps each primary destination to its selected tab when unpinned', () {
      expect(ShelterBottomNavigation.indexFor('/o/orgs'), 0);
      expect(ShelterBottomNavigation.indexFor('/o/orgs/discover'), 3);
      expect(
        ShelterBottomNavigation.indexFor('/o/orgs/discover?from=dashboard'),
        3,
      );
      expect(ShelterBottomNavigation.indexFor('/account'), 4);
    });

    test('maps pinned org routes to slot 1 when pin matches', () {
      expect(
        ShelterBottomNavigation.indexFor(
          '/o/orgs/org-pin-1',
          pinnedOrg: _pinnedOrg,
        ),
        1,
      );
      expect(
        ShelterBottomNavigation.indexFor(
          '/o/orgs/org-pin-1/pets',
          pinnedOrg: _pinnedOrg,
        ),
        1,
      );
      expect(
        ShelterBottomNavigation.indexFor(
          '/o/orgs/other-org',
          pinnedOrg: _pinnedOrg,
        ),
        0,
      );
    });

    test('maps nested shelter routes to dashboard when unpinned', () {
      expect(ShelterBottomNavigation.indexFor('/o/orgs/org-1'), 0);
      expect(ShelterBottomNavigation.indexFor('/o/orgs/org-1/pets'), 0);
      expect(ShelterBottomNavigation.indexFor('/o/orgs/new'), 0);
      expect(ShelterBottomNavigation.indexFor('/account/orgs/org-1'), 4);
    });

    test('recognises shelter workspace routes', () {
      expect(ShelterBottomNavigation.supports('/o/orgs'), isTrue);
      expect(ShelterBottomNavigation.supports('/o/orgs/discover'), isTrue);
      expect(ShelterBottomNavigation.supports('/o/orgs/org-1/pets'), isTrue);
      expect(ShelterBottomNavigation.supports('/account'), isTrue);
      expect(ShelterBottomNavigation.supports('/o/onboarding'), isFalse);
      expect(ShelterBottomNavigation.supports('/pc/home'), isFalse);
    });

    test('uses the same breakpoints as guardian shell nav', () {
      expect(ShelterBottomNavigation.isCompact(599), isTrue);
      expect(ShelterBottomNavigation.isCompact(600), isFalse);
      expect(ShelterPrimaryDestinations.isMedium(600), isTrue);
      expect(ShelterPrimaryDestinations.isMedium(839), isTrue);
      expect(ShelterPrimaryDestinations.isExpanded(840), isTrue);
    });
  });

  group('ShelterBottomNavigation widget', () {
    testWidgets('renders tab labels for unpinned destinations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            bottomNavigationBar: const ShelterBottomNavigation(
              currentLocation: '/o/orgs',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Discover Organisations'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Happy Tails'), findsNothing);
      expect(
        find.byKey(const Key('shelter_bottom_navigation')),
        findsOneWidget,
      );
    });

    testWidgets('renders pinned org label when pin is set', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            bottomNavigationBar: ShelterBottomNavigation(
              currentLocation: '/o/orgs/org-pin-1',
              pinnedOrg: _pinnedOrg,
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
  });
}
