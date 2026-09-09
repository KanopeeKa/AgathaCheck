import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_establishment.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_source.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/care_progression_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/pet_care_rhythms_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

class _TestHealthEntriesNotifier extends HealthEntriesNotifier {
  _TestHealthEntriesNotifier(this._entries);

  final List<HealthEntry> _entries;

  @override
  Future<List<HealthEntry>> build() async => _entries;
}

class _EmptyOrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => [];
}

void main() {
  const pet = Pet(id: 'pet-1', name: 'Rex', species: 'Dog', breed: 'Mix');

  final recurring = HealthEntry(
    id: 'rhythm-1',
    petId: 'pet-1',
    name: 'Flea treatment',
    type: HealthEntryType.preventive,
    frequency: HealthFrequency.monthly,
    frequencyInterval: 12,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime(2026, 10, 21),
    careSource: CareSource.guardianDefined,
  );

  final oneTime = HealthEntry(
    id: 'once-1',
    petId: 'pet-1',
    name: 'Grooming',
    type: HealthEntryType.other,
    frequency: HealthFrequency.once,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime(2026, 10, 1),
  );

  final weightRhythm = HealthEntry(
    id: 'weight-1',
    petId: 'pet-1',
    name: 'Weight monitoring',
    type: HealthEntryType.other,
    frequency: HealthFrequency.weekly,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime(2026, 10, 21),
    careFamily: CareFamily.weightMonitoring,
    careSource: CareSource.guardianDefined,
  );

  Widget buildApp({
    required List<HealthEntry> entries,
    List<CareEstablishment> establishments = const [],
  }) {
    final router = GoRouter(
      initialLocation: '/pet/pet-1/care-rhythms',
      routes: [
        GoRoute(
          path: '/pet/:petId',
          builder: (context, state) => const Scaffold(body: Text('Profile')),
        ),
        GoRoute(
          path: '/pet/:petId/care-rhythms',
          builder: (context, state) =>
              PetCareRhythmsScreen(petId: state.pathParameters['petId']!),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        experienceEligibilityProvider.overrideWith(
          (ref) => AsyncValue.data(
            ExperienceEligibilityRules.compute(
              pets: [pet],
              orgMembershipCount: 0,
            ),
          ),
        ),
        organizationListProvider.overrideWith(_EmptyOrgListNotifier.new),
        combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
        guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
        orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
        allPetsIncludingOrgProvider.overrideWith((ref) async => [pet]),
        healthEntriesNotifierProvider.overrideWith(
          () => _TestHealthEntriesNotifier(entries),
        ),
        petCareEstablishmentsProvider('pet-1').overrideWith(
          (ref) async => establishments,
        ),
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

  testWidgets('shows subtitle and recurring rhythms only', (tester) async {
    await tester.pumpWidget(buildApp(entries: [recurring, oneTime]));
    await tester.pumpAndSettle();

    expect(find.text('Care Rhythms'), findsOneWidget);
    expect(find.text('Your recurring care routines.'), findsOneWidget);
    expect(find.text('Flea treatment'), findsOneWidget);
    expect(find.text('Grooming'), findsNothing);
    expect(find.text('Added by you'), findsOneWidget);
    expect(find.byKey(const Key('care_rhythms_list')), findsOneWidget);
  });

  testWidgets('shows Established marker for weight rhythm when established', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        entries: [weightRhythm],
        establishments: [
          CareEstablishment(
            id: 'est-1',
            careFamily: CareFamily.weightMonitoring,
            healthEntryId: 'weight-1',
            establishedAt: DateTime(2026, 1, 1),
            policyVersion: 'weight_v1',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weight monitoring'), findsOneWidget);
    expect(find.text('Established'), findsOneWidget);
  });

  testWidgets('shows empty state when no recurring entries', (tester) async {
    await tester.pumpWidget(buildApp(entries: [oneTime]));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No recurring care routines yet. Add a recurring event to see it here.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('care_rhythms_list')), findsNothing);
  });
}
