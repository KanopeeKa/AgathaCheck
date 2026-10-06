import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/detail/care_item_detail_screen.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_entry_absence_context_model.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_history_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/care_item_absence_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/occurrence_providers.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/care_progression_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_entry.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/providers/weight_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

class _EmptyWeightEntriesNotifier extends WeightEntriesNotifier {
  @override
  Future<List<WeightEntry>> build(String arg) async => [];
}

class _TestHealthEntriesNotifier extends HealthEntriesNotifier {
  _TestHealthEntriesNotifier(this._entries);

  final List<HealthEntry> _entries;

  @override
  Future<List<HealthEntry>> build() async => _entries;
}

class _LoadingHealthEntriesNotifier extends HealthEntriesNotifier {
  _LoadingHealthEntriesNotifier(this._completer);

  final Completer<List<HealthEntry>> _completer;

  @override
  Future<List<HealthEntry>> build() => _completer.future;
}

Future<List<HealthHistoryEntry>> _emptyHistory(Ref ref, String entryId) async =>
    [];

void main() {
  const pet = Pet(id: 'pet-1', name: 'Rex', species: 'Dog');
  final entry = HealthEntry(
    id: 'entry-1',
    petId: 'pet-1',
    name: 'DHPP',
    type: HealthEntryType.preventive,
    frequency: HealthFrequency.yearly,
    frequencyInterval: 1,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime(2026, 6, 1),
  );

  List<Override> baseOverrides({
    required Future<List<Pet>> Function(Ref ref) petsFuture,
    HealthEntriesNotifier Function()? healthEntries,
  }) {
    return [
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      allPetsIncludingOrgProvider.overrideWith(petsFuture),
      organizationListProvider.overrideWith(FakeOrganizationListNotifier.new),
      healthEntriesNotifierProvider.overrideWith(
        healthEntries ?? () => _TestHealthEntriesNotifier([entry]),
      ),
      entryHistoryProvider.overrideWith(_emptyHistory),
      entryOccurrencesProvider.overrideWith((ref, id) async => []),
      petCareEstablishmentsProvider.overrideWith((ref, petId) async => []),
      careItemAbsenceContextProvider('entry-1').overrideWith(
        (ref) async => const HealthEntryAbsenceContext(
          healthEntryId: 'entry-1',
          petId: 'pet-1',
          absences: [],
        ),
      ),
      experienceEligibilityProvider.overrideWith(
        (ref) => AsyncValue.data(
          ExperienceEligibilityRules.compute(
            pets: [pet],
            orgMembershipCount: 0,
          ),
        ),
      ),
      combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
      guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
      orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
      apiBaseUrlProvider.overrideWithValue('http://test.local'),
      weightEntriesNotifierProvider.overrideWith(
        () => _EmptyWeightEntriesNotifier(),
      ),
    ];
  }

  Widget buildApp({
    required List<Override> overrides,
    required String initialLocation,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/pet/:petId/events/:entryId',
          builder: (context, state) => CareItemDetailScreen(
            petId: state.pathParameters['petId']!,
            entryId: state.pathParameters['entryId']!,
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('shows Care details title while pets load', (tester) async {
    final petsCompleter = Completer<List<Pet>>();
    await tester.pumpWidget(
      buildApp(
        initialLocation: '/pet/pet-1/events/entry-1',
        overrides: baseOverrides(petsFuture: (ref) => petsCompleter.future),
      ),
    );
    await tester.pump();

    expect(find.text('Care details'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows Care details title when pet is missing', (tester) async {
    await tester.pumpWidget(
      buildApp(
        initialLocation: '/pet/pet-1/events/entry-1',
        overrides: baseOverrides(petsFuture: (ref) async => <Pet>[]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Care details'), findsOneWidget);
    expect(find.text('Pet not found'), findsOneWidget);
  });

  testWidgets('shows Care details title when entry is missing', (tester) async {
    await tester.pumpWidget(
      buildApp(
        initialLocation: '/pet/pet-1/events/missing-entry',
        overrides: baseOverrides(
          petsFuture: (ref) async => [pet],
          healthEntries: () => _TestHealthEntriesNotifier([entry]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Care details'), findsOneWidget);
    expect(find.text('Entry not found'), findsOneWidget);
  });

  testWidgets('shows Care details title while entry loads', (tester) async {
    final entriesCompleter = Completer<List<HealthEntry>>();
    await tester.pumpWidget(
      buildApp(
        initialLocation: '/pet/pet-1/events/entry-1',
        overrides: baseOverrides(
          petsFuture: (ref) async => [pet],
          healthEntries: () => _LoadingHealthEntriesNotifier(entriesCompleter),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Care details'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
