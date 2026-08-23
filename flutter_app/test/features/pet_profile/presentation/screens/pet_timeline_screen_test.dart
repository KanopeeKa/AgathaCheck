import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_timeline_segment.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_timeline_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/pet_timeline_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

class _EmptyOrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => [];
}

class _TestPetListNotifier extends PetListNotifier {
  _TestPetListNotifier(this.pets);

  final List<Pet> pets;

  @override
  Future<List<Pet>> build() async => pets;
}

void main() {
  final testPet = Pet(
    id: 'pet-1',
    name: 'Rex',
    species: 'Dog',
    dateOfBirth: DateTime(2020, 3, 15),
    createdAt: DateTime(2024, 1, 10),
    guardianName: 'Jane Doe',
  );

  Widget buildApp({
    required String initialLocation,
    List<Pet> pets = const [],
    List<PetTimelineSegment> timelineSegments = const [],
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/pet/:petId',
          builder: (context, state) => const Scaffold(body: Text('Profile')),
        ),
        GoRoute(
          path: '/pet/:petId/timeline',
          builder: (context, state) =>
              PetTimelineScreen(petId: state.pathParameters['petId']!),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        // removed resolvedExperienceProvider mock
        experienceEligibilityProvider.overrideWith(
          (ref) => AsyncValue.data(
            ExperienceEligibilityRules.compute(
              pets: pets.isEmpty ? [testPet] : pets,
              orgMembershipCount: 0,
            ),
          ),
        ),
        organizationListProvider.overrideWith(_EmptyOrgListNotifier.new),
        combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
        guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
        orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
        apiBaseUrlProvider.overrideWithValue('http://test.local'),
        petListProvider.overrideWith(
          () => _TestPetListNotifier(pets.isEmpty ? [testPet] : pets),
        ),
        petTimelineProvider.overrideWith(
          (ref, petId) async => timelineSegments,
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('timeline screen shows title and back returns to profile', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(initialLocation: '/pet/pet-1'));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Profile'));
    GoRouter.of(context).push('/pet/pet-1/timeline');
    await tester.pumpAndSettle();

    expect(find.text('Timeline'), findsOneWidget);
    expect(find.byKey(const Key('pet_timeline_list')), findsOneWidget);

    await tester.tap(find.byKey(const Key('experience_back_button')));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('shows DOB and joined markers when pet data exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        initialLocation: '/pet/pet-1/timeline',
        timelineSegments: const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Date of Birth'), findsOneWidget);
    expect(find.text('Joined AgathaTrack'), findsOneWidget);
    expect(find.text('Guardian: Jane Doe'), findsOneWidget);
    expect(find.text('2020-03-15'), findsOneWidget);
    expect(find.text('2024-01-10'), findsOneWidget);
  });

  testWidgets('shows fostering session read-only without edit actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        initialLocation: '/pet/pet-1/timeline',
        timelineSegments: const [
          PetTimelineSegment(
            kind: 'fostering_session',
            id: 'fp-1',
            startDate: '2025-06-01',
            endDate: '2025-08-31',
            fosterName: 'Frank',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fostering with Frank'), findsOneWidget);
    expect(find.text('2025-06-01 – 2025-08-31'), findsOneWidget);
    expect(find.byKey(const Key('timeline_edit_fp-1')), findsNothing);
    expect(find.byKey(const Key('timeline_delete_fp-1')), findsNothing);
  });

  testWidgets('shows custody segment read-only without edit actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        initialLocation: '/pet/pet-1/timeline',
        timelineSegments: const [
          PetTimelineSegment(
            kind: 'custody',
            id: 'custody-1',
            startDate: '2024-06-01',
            guardianName: 'Bob',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final custodyCard = find.byKey(
      const Key('timeline_entry_custody_custody-1'),
    );
    expect(
      find.descendant(of: custodyCard, matching: find.text('Guardian: Bob')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('timeline_edit_custody-1')), findsNothing);
    expect(find.byKey(const Key('timeline_delete_custody-1')), findsNothing);
  });

  testWidgets('shows fillable gap with fill action', (tester) async {
    await tester.pumpWidget(
      buildApp(
        initialLocation: '/pet/pet-1/timeline',
        timelineSegments: const [
          PetTimelineSegment(
            kind: 'gap',
            id: 'gap-1',
            startDate: '2023-01-01',
            endDate: '2023-12-31',
            fillable: true,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No data'), findsOneWidget);
    expect(find.text('2023-01-01 – 2023-12-31'), findsOneWidget);
    expect(find.byKey(const Key('timeline_fill_gap-1')), findsOneWidget);
    expect(find.byKey(const Key('timeline_edit_gap-1')), findsNothing);
  });

  testWidgets('shows manual entry with edit and delete actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        initialLocation: '/pet/pet-1/timeline',
        timelineSegments: const [
          PetTimelineSegment(
            kind: 'manual',
            id: 'manual-1',
            startDate: '2025-01-01',
            title: 'First vet visit',
            description: 'Annual checkup',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('First vet visit'), findsOneWidget);
    expect(find.text('Annual checkup'), findsOneWidget);
    expect(find.byKey(const Key('timeline_edit_manual-1')), findsOneWidget);
    expect(find.byKey(const Key('timeline_delete_manual-1')), findsOneWidget);
  });

  testWidgets('entries are sorted latest first by start date', (tester) async {
    await tester.pumpWidget(
      buildApp(
        initialLocation: '/pet/pet-1/timeline',
        timelineSegments: const [
          PetTimelineSegment(
            kind: 'manual',
            id: 'old',
            startDate: '2023-01-01',
            title: 'Older entry',
          ),
          PetTimelineSegment(
            kind: 'manual',
            id: 'new',
            startDate: '2025-06-01',
            title: 'Newer entry',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final titles = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const Key('pet_timeline_list')),
            matching: find.byType(Text),
          ),
        )
        .map((w) => w.data)
        .whereType<String>()
        .toList();

    final newerIndex = titles.indexOf('Newer entry');
    final olderIndex = titles.indexOf('Older entry');
    expect(newerIndex, greaterThan(-1));
    expect(olderIndex, greaterThan(-1));
    expect(newerIndex, lessThan(olderIndex));
  });

  testWidgets('shows year dividers when entries span multiple years', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        initialLocation: '/pet/pet-1/timeline',
        timelineSegments: const [
          PetTimelineSegment(
            kind: 'manual',
            id: 'new',
            startDate: '2025-06-01',
            title: 'Newer entry',
          ),
          PetTimelineSegment(
            kind: 'manual',
            id: 'old',
            startDate: '2023-01-01',
            title: 'Older entry',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Top of list (newest years) is visible without scrolling.
    expect(find.byKey(const Key('pet_timeline_year_2025')), findsOneWidget);
    expect(find.byKey(const Key('pet_timeline_year_2024')), findsOneWidget);
    expect(find.byKey(const Key('pet_timeline_year_2023')), findsOneWidget);

    // DOB year divider is below the fold in the lazy list.
    await tester.scrollUntilVisible(
      find.byKey(const Key('pet_timeline_year_2020')),
      120,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pet_timeline_year_2020')), findsOneWidget);
  });

  testWidgets('add buttons are present in app bar and bottom', (tester) async {
    await tester.pumpWidget(buildApp(initialLocation: '/pet/pet-1/timeline'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pet_timeline_add_app_bar')), findsOneWidget);
    expect(find.byKey(const Key('pet_timeline_add_bottom')), findsOneWidget);
  });
}
