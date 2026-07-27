import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/pet_detail_screen.dart';
import 'package:pet_profile_app/features/sharing/domain/entities/pet_access.dart';
import 'package:pet_profile_app/features/sharing/domain/entities/share_link.dart';
import 'package:pet_profile_app/features/sharing/domain/repositories/sharing_repository.dart';
import 'package:pet_profile_app/features/sharing/presentation/providers/sharing_providers.dart';
import 'package:pet_profile_app/features/vet/presentation/providers/vet_providers.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/providers/weight_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

class _FakeSharingRepository implements SharingRepository {
  @override
  Future<List<PetAccess>> getAccess(String petId, String token) async => [];

  @override
  Future<List<ShareLink>> getShareLinks(String petId, String token) async => [];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const ownedPet = Pet(id: 'pet-1', name: 'Rex', species: 'Dog');
  const sharedPet = Pet(
    id: 'pet-2',
    name: 'Milo',
    species: 'Cat',
    isShared: true,
    guardianName: 'Alex',
  );

  Widget buildApp({required Pet pet, required String initialLocation}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/pet/:petId',
          builder: (context, state) =>
              PetDetailScreen(petId: state.pathParameters['petId']!),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        resolvedExperienceProvider.overrideWith(
          (ref) => AppExperience.guardian,
        ),
        experienceEligibilityProvider.overrideWith(
          (ref) => AsyncValue.data(
            ExperienceEligibilityRules.compute(
              pets: [pet],
              orgMembershipCount: 0,
            ),
          ),
        ),
        allPetsIncludingOrgProvider.overrideWith((ref) async => [pet]),
        organizationListProvider.overrideWith(FakeOrganizationListNotifier.new),
        healthEntriesNotifierProvider.overrideWith(
          FakeHealthEntriesNotifier.new,
        ),
        combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
        guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
        orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
        apiBaseUrlProvider.overrideWithValue('http://test.local'),
        sharingRepositoryProvider.overrideWith(
          (ref) => _FakeSharingRepository(),
        ),
        vetListProvider.overrideWith(FakeVetListNotifier.new),
        latestWeightProvider.overrideWith((ref, arg) => null),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('owned pet shows sharing and export contextual actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(pet: ownedPet, initialLocation: '/pet/pet-1'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pet_detail_sharing_action')), findsOneWidget);
    expect(
      find.byKey(const Key('pet_detail_export_report_action')),
      findsOneWidget,
    );
    expect(find.text('Sharing'), findsNothing);
  });

  testWidgets('shared pet shows sharing action only', (tester) async {
    await tester.pumpWidget(
      buildApp(pet: sharedPet, initialLocation: '/pet/pet-2'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pet_detail_sharing_action')), findsOneWidget);
    expect(
      find.byKey(const Key('pet_detail_export_report_action')),
      findsOneWidget,
    );
  });

  testWidgets('sharing action opens bottom sheet', (tester) async {
    await tester.pumpWidget(
      buildApp(pet: ownedPet, initialLocation: '/pet/pet-1'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pet_detail_sharing_action')));
    await tester.pumpAndSettle();

    expect(find.text('Sharing'), findsWidgets);
  });

  testWidgets('export action opens section picker dialog', (tester) async {
    await tester.pumpWidget(
      buildApp(pet: ownedPet, initialLocation: '/pet/pet-1'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pet_detail_export_report_action')));
    await tester.pumpAndSettle();

    expect(find.text('Download Pet Report'), findsWidgets);
    expect(find.text('Pet Profile'), findsOneWidget);
  });
}
