import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/people/application/people_providers.dart';
import 'package:pet_profile_app/features/people/domain/entities/household.dart';
import 'package:pet_profile_app/features/people/domain/entities/roster.dart';
import 'package:pet_profile_app/features/people/presentation/detail/person_detail_page.dart';
import 'package:pet_profile_app/features/people/presentation/households/household_detail_page.dart';
import 'package:pet_profile_app/features/people/presentation/households/households_page.dart';
import 'package:pet_profile_app/features/people/presentation/screens/legacy_vet_contact_redirect_screen.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../helpers/fakes.dart';
import '../application/people_providers_test.dart';
import 'hub/people_hub_test_support.dart';
import 'people_test_harness.dart';

var _householdListAttempts = 0;
var _legacyVetAttempts = 0;
var _rosterAttempts = 0;
var _householdPetsAttempts = 0;

class _FlakyHouseholdsList extends FakeHouseholdsRepository {
  @override
  Future<List<Household>> listHouseholds() async {
    _householdListAttempts++;
    if (_householdListAttempts < 2) {
      throw Exception('network');
    }
    return const [];
  }
}

class _FlakyRosterNotifier extends RosterNotifier {
  @override
  Future<Roster> build() async {
    _rosterAttempts++;
    if (_rosterAttempts < 2) {
      throw Exception('network');
    }
    return sampleHubRoster();
  }

  @override
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

class _FlakyHouseholdPetsNotifier extends PetListNotifier {
  @override
  Future<List<Pet>> build() async {
    _householdPetsAttempts++;
    if (_householdPetsAttempts < 2) {
      throw Exception('network');
    }
    return [const Pet(id: 'p1', name: 'Buddy', species: 'Dog')];
  }
}

void main() {
  setUp(() {
    _householdListAttempts = 0;
    _legacyVetAttempts = 0;
    _rosterAttempts = 0;
    _householdPetsAttempts = 0;
  });

  testWidgets('households list error shows Retry then loads', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          householdsRepositoryProvider.overrideWithValue(
            _FlakyHouseholdsList(),
          ),
        ],
        child: peopleTestApp(child: const HouseholdsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load contacts. Try again.'), findsOneWidget);
    expect(find.textContaining('network'), findsNothing);

    await tester.tap(find.byKey(const Key('households_list_retry')));
    await tester.pumpAndSettle();

    expect(find.text('Create household'), findsOneWidget);
  });

  testWidgets('household detail hides other-owner label while pets fail', (
    tester,
  ) async {
    final household = Household(
      id: 'hh-1',
      name: 'Morgan household',
      myTier: 'full_access',
      myIsOrganiser: true,
      members: const [
        HouseholdMember(
          userId: 'test-user-id',
          displayName: 'Alex',
          firstName: 'Alex',
          tier: 'full_access',
          isOrganiser: true,
          isYou: true,
          ownsPetIds: ['p1'],
          sharesPetIds: [],
        ),
      ],
      pets: const [
        HouseholdPet(petId: 'p1', name: 'Buddy', ownerUserId: 'test-user-id'),
      ],
    );
    final fake = FakeHouseholdsRepository()..detail = household;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          householdsRepositoryProvider.overrideWithValue(fake),
          rosterProvider.overrideWith(
            () => _StaticRosterNotifier(
              const Roster(households: [], contacts: [], pendingInvites: []),
            ),
          ),
          petListProvider.overrideWith(() => _FlakyHouseholdPetsNotifier()),
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
        ],
        child: peopleTestApp(
          child: const HouseholdDetailPage(householdId: 'hh-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your pets could not be loaded'), findsOneWidget);
    expect(find.text('Owned by another household member'), findsNothing);
    expect(find.text('Buddy'), findsOneWidget);
  });

  testWidgets('legacy vet mapping error shows Retry not endless spinner', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/pc/vets/vet-legacy-1',
      routes: [
        GoRoute(
          path: '/pc/vets/:id',
          builder: (context, state) => LegacyVetContactRedirectScreen(
            vetId: state.pathParameters['id']!,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          legacyVetContactIdProvider.overrideWith((ref, vetId) async {
            _legacyVetAttempts++;
            if (_legacyVetAttempts < 2) {
              throw Exception('network');
            }
            return 'contact-42';
          }),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load contacts. Try again.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byKey(const Key('legacy_vet_redirect_retry')));
    await tester.pumpAndSettle();

    expect(find.text('Could not load contacts. Try again.'), findsNothing);
  });

  testWidgets('person detail roster error shows Retry', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rosterProvider.overrideWith(() => _FlakyRosterNotifier()),
          peopleRepositoryProvider.overrideWithValue(FakePeopleRepository()),
          householdsRepositoryProvider.overrideWithValue(
            FakeHouseholdsRepository(),
          ),
        ],
        child: peopleTestApp(
          child: const PersonDetailPage(personId: 'carer-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load contacts. Try again.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('person_detail_roster_retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('person_detail_roster_retry')), findsNothing);
    expect(find.text('Could not load contacts. Try again.'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Overview'), findsOneWidget);
  });
}

class _StaticRosterNotifier extends RosterNotifier {
  _StaticRosterNotifier(this._roster);

  final Roster _roster;

  @override
  Future<Roster> build() async => _roster;
}
