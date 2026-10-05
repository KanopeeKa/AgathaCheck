import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/people/application/people_providers.dart';
import 'package:pet_profile_app/features/people/domain/entities/household.dart';
import 'package:pet_profile_app/features/people/domain/entities/household_invite.dart';
import 'package:pet_profile_app/features/people/domain/entities/roster.dart';
import 'package:pet_profile_app/features/people/presentation/households/household_detail_page.dart';
import 'package:pet_profile_app/features/people/presentation/households/household_invite_landing_screen.dart';
import 'package:pet_profile_app/core/router/experience_routes.dart';
import 'package:pet_profile_app/features/people/presentation/households/households_page.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../application/people_providers_test.dart';
import '../people_test_harness.dart';

void main() {
  test('legacy /pc/pets/households redirects to people households', () {
    GoRoute? legacyRoute;
    void visit(RouteBase route) {
      if (route is GoRoute) {
        if (route.name == 'petCareHouseholds') legacyRoute = route;
        for (final child in route.routes) {
          visit(child);
        }
      } else if (route is ShellRoute) {
        for (final child in route.routes) {
          visit(child);
        }
      }
    }
    for (final route in buildExperienceRoutes()) {
      visit(route);
    }
    expect(legacyRoute, isNotNull);
    expect(legacyRoute!.redirect, isNotNull);
  });

  final household = Household(
    id: 'hh-1',
    name: 'Morgan household',
    myTier: 'full_access',
    myIsOrganiser: true,
    members: const [
      HouseholdMember(
        userId: 'test-user-id',
        displayName: 'Alex Morgan',
        firstName: 'Alex',
        tier: 'full_access',
        isOrganiser: true,
        isYou: true,
        ownsPetIds: ['p1'],
        sharesPetIds: [],
      ),
      HouseholdMember(
        userId: 'u2',
        displayName: 'Sam Lee',
        firstName: 'Sam',
        tier: 'can_log_care',
        isOrganiser: false,
        isYou: false,
        ownsPetIds: [],
        sharesPetIds: ['p1'],
      ),
    ],
    pets: const [
      HouseholdPet(petId: 'p1', name: 'Buddy', ownerUserId: 'test-user-id'),
    ],
  );

  final pendingInvite = HouseholdInvite(
    id: 'inv-1',
    source: 'household',
    email: 'guest@example.com',
    householdId: 'hh-1',
    petIds: const [],
  );

  ProviderScope buildScope({
    required Widget child,
    FakeHouseholdsRepository? households,
    Roster? roster,
  }) {
    final fake = households ?? FakeHouseholdsRepository();
    fake.detail = household;
    return ProviderScope(
      overrides: [
        householdsRepositoryProvider.overrideWithValue(fake),
        rosterProvider.overrideWith(
          () => _StaticRosterNotifier(
            roster ??
                Roster(
                  households: [household],
                  contacts: const [],
                  pendingInvites: [pendingInvite],
                ),
          ),
        ),
        petListProvider.overrideWith(
          () => TestPetListNotifier([
            Pet(id: 'p1', name: 'Buddy', species: 'Dog', breed: 'Mix'),
          ]),
        ),
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ],
      child: child,
    );
  }

  testWidgets('create household flow includes pet review step', (tester) async {
    final fake = FakeHouseholdsRepository();
    await tester.pumpWidget(
      buildScope(
        households: fake,
        child: peopleTestApp(child: const HouseholdsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('households_create')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'New home');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Continue'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pets in this household'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Create household'),
      ),
    );
    await tester.pumpAndSettle();

    expect(fake.detail?.name, 'New home');
  });

  testWidgets('organiser can invite and revoke on detail page', (tester) async {
    final fake = FakeHouseholdsRepository();
    await tester.pumpWidget(
      buildScope(
        households: fake,
        child: peopleTestApp(
          child: const HouseholdDetailPage(householdId: 'hh-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('household_invite_member')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('household_invite_email')),
      'new@example.com',
    );
    await tester.tap(
      find.ancestor(
        of: find.text('They are 18 or over'),
        matching: find.byType(CheckboxListTile),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('household_invite_submit')));
    await tester.pumpAndSettle();
    expect(fake.lastInviteEmail, 'new@example.com');

    await tester.tap(find.byKey(const Key('household_revoke_inv-1')));
    await tester.pumpAndSettle();
    expect(fake.inviteRevoked, isTrue);
  });

  testWidgets('organiser can rename household', (tester) async {
    final fake = FakeHouseholdsRepository();
    await tester.pumpWidget(
      buildScope(
        households: fake,
        child: peopleTestApp(
          child: const HouseholdDetailPage(householdId: 'hh-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('household_rename')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Renamed');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(fake.renamed, isTrue);
  });

  testWidgets('household invite landing accept and decline', (tester) async {
    final fake = FakeHouseholdsRepository();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SizedBox()),
        GoRoute(
          path: '/household-invite/:code',
          builder: (_, state) => HouseholdInviteLandingScreen(
            inviteCode: state.pathParameters['code']!,
          ),
        ),
        GoRoute(
          path: '/pc/people/households/:id',
          builder: (_, __) => const SizedBox(key: Key('detail')),
        ),
        GoRoute(path: '/pc/home', builder: (_, __) => const SizedBox()),
      ],
    );
    await tester.pumpWidget(
      buildScope(
        households: fake,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    router.go('/household-invite/abc123');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('household_invite_accept')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('detail')), findsOneWidget);

    router.go('/household-invite/abc123');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('household_invite_decline')));
    await tester.pumpAndSettle();
  });
}

class _StaticRosterNotifier extends RosterNotifier {
  _StaticRosterNotifier(this._roster);

  final Roster _roster;

  @override
  Future<Roster> build() async => _roster;
}
