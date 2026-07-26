import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/pet_manage_events_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

void main() {
  const pet = Pet(id: 'pet-1', name: 'Rex', species: 'Dog', breed: 'Mix');

  Widget buildScreen() {
    final router = GoRouter(
      initialLocation: '/pet/pet-1/events',
      routes: [
        GoRoute(
          path: '/pet/:petId/events',
          builder: (context, state) =>
              PetManageEventsScreen(petId: state.pathParameters['petId']!),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        resolvedExperienceProvider.overrideWith(
          (ref) => AppExperience.guardian,
        ),
        allPetsIncludingOrgProvider.overrideWith((ref) async => [pet]),
        healthEntriesNotifierProvider.overrideWith(
          FakeHealthEntriesNotifier.new,
        ),
        combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
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

  testWidgets('manage events screen shows Edit and History tabs', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Manage events'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });
}
