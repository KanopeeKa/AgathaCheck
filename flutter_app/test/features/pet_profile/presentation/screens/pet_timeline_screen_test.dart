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
import 'package:pet_profile_app/features/pet_profile/presentation/screens/pet_timeline_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

class _EmptyOrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => [];
}

void main() {
  Widget buildApp({required String initialLocation}) {
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
        resolvedExperienceProvider.overrideWith(
          (ref) => AppExperience.guardian,
        ),
        experienceEligibilityProvider.overrideWith(
          (ref) => AsyncValue.data(
            ExperienceEligibilityRules.compute(
              pets: const [Pet(id: 'pet-1', name: 'Rex', species: 'Dog')],
              orgMembershipCount: 0,
            ),
          ),
        ),
        organizationListProvider.overrideWith(_EmptyOrgListNotifier.new),
        combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
        guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
        orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
        apiBaseUrlProvider.overrideWithValue('http://test.local'),
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
    expect(find.text('Coming soon'), findsOneWidget);

    await tester.tap(find.byKey(const Key('experience_back_button')));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
  });
}
