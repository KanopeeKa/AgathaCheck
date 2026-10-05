import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/core/weight/weight_unit.dart';
import 'package:pet_profile_app/core/weight/weight_unit_preference.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_entry.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_fulfils.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_overview.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/providers/weight_providers.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/screens/weight_hub_screen.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/health_entry_form_screen.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/navigation/weight_care_add_navigation.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/widgets/weight_chart.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../helpers/fakes.dart';

class _FakeWeightEntriesNotifier extends WeightEntriesNotifier {
  _FakeWeightEntriesNotifier(this._entries);

  final List<WeightEntry> _entries;

  @override
  Future<List<WeightEntry>> build(String arg) async => _entries;
}

class _EmptyOrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => [];
}

WeightEntry _entry(
  String id,
  DateTime date,
  double weight, {
  WeightFulfils? fulfils,
  String source = 'guardian',
}) => WeightEntry(
  id: id,
  petId: 'pet-1',
  date: date,
  weight: weight,
  fulfils: fulfils,
  measurementSource: source,
);

WeightOverview _overviewWithRoutines(int count) {
  final routines = List.generate(
    count,
    (i) => WeightRoutine(
      entryId: 'care-$i',
      name: 'Routine $i',
      status: 'active',
      next: WeightRoutineNext(
        occurrenceId: 'occ-$i',
        scheduledDate: DateTime(2026, 5, 10 + i),
        status: 'due',
      ),
    ),
  );
  return WeightOverview(
    petId: 'pet-1',
    routines: routines,
    reference: const WeightReference(valueKg: 10, authority: 'vet_target'),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp({
    required List<WeightEntry> entries,
    required String initialLocation,
    WeightOverview? overview,
    List<Override> extraOverrides = const [],
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/pet/:petId',
          builder: (context, state) => const Scaffold(body: Text('Profile')),
        ),
        GoRoute(
          path: '/pet/:petId/weight',
          builder: (context, state) =>
              WeightHubScreen(petId: state.pathParameters['petId']!),
        ),
        GoRoute(
          path: '/pet/:petId/care/add',
          builder: (context, state) => HealthEntryFormScreen(
            petId: state.pathParameters['petId'],
            initialCareFamily: CareFamilyWire.fromWire(
              state.uri.queryParameters['family'],
            ),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
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
        weightEntriesNotifierProvider.overrideWith(
          () => _FakeWeightEntriesNotifier(entries),
        ),
        weightOverviewProvider.overrideWith(
          (ref, petId) async =>
              overview ?? WeightOverview(petId: petId, routines: []),
        ),
        ...extraOverrides,
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('FW-6 hub shows summary, chart, routines and history chips', (
    tester,
  ) async {
    final fulfils = WeightFulfils(
      entryId: 'care-1',
      entryName: 'Weekly weigh-in',
      occurrenceId: 'occ-1',
      scheduledDate: DateTime(2026, 4, 1),
    );
    final entries = [
      _entry('w2', DateTime(2026, 2, 1), 11.5, fulfils: fulfils),
      _entry('w1', DateTime(2026, 1, 1), 10.0, source: 'clinic'),
    ];
    await tester.pumpWidget(
      buildApp(
        entries: entries,
        initialLocation: '/pet/pet-1/weight',
        overview: _overviewWithRoutines(2),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('weight_hub_summary')), findsOneWidget);
    expect(find.byType(WeightChart), findsOneWidget);
    expect(find.byKey(const Key('weight_hub_routines')), findsOneWidget);
    expect(find.text('Routine 0'), findsOneWidget);
    expect(find.text('Routine 1'), findsOneWidget);
    expect(find.text('Counts as Weekly weigh-in'), findsOneWidget);
    expect(find.text('From the vet'), findsOneWidget);
    expect(find.textContaining('Target'), findsOneWidget);
  });

  testWidgets('FW-20 set up weigh-in routine opens care add with family', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        entries: [_entry('w1', DateTime(2026, 1, 1), 10)],
        initialLocation: '/pet/pet-1/weight',
        overview: const WeightOverview(petId: 'pet-1', routines: []),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Set up a weigh-in routine'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(HealthEntryFormScreen));
    final router = GoRouter.of(context);
    expect(router.state.uri.toString(), weightMonitoringCareAddPath('pet-1'));
  });

  testWidgets('FW-6 routines card empty state', (tester) async {
    await tester.pumpWidget(
      buildApp(
        entries: [_entry('w1', DateTime(2026, 1, 1), 10)],
        initialLocation: '/pet/pet-1/weight',
        overview: const WeightOverview(petId: 'pet-1', routines: []),
      ),
    );
    await tester.pump();

    expect(find.text('No weigh-in routine'), findsOneWidget);
    expect(find.text('Set up a weigh-in routine'), findsOneWidget);
  });

  testWidgets('shows title, back navigation, and empty state', (tester) async {
    await tester.pumpWidget(
      buildApp(entries: const [], initialLocation: '/pet/pet-1'),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Profile'));
    GoRouter.of(context).push('/pet/pet-1/weight');
    await tester.pumpAndSettle();

    expect(find.text('Weight Tracking'), findsOneWidget);
    expect(find.text('No weight data yet'), findsOneWidget);
    expect(find.byType(WeightChart), findsNothing);
    expect(
      find.byKey(const Key('weight_tracking_add_app_bar')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('weight_tracking_add_footer')), findsOneWidget);

    await tester.tap(find.byKey(const Key('experience_back_button')));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('renders the weight chart when two or more entries exist', (
    tester,
  ) async {
    final entries = [
      _entry('w1', DateTime(2026, 1, 1), 10.0),
      _entry('w2', DateTime(2026, 2, 1), 11.5),
      _entry('w3', DateTime(2026, 3, 1), 11.0),
    ];
    await tester.pumpWidget(
      buildApp(entries: entries, initialLocation: '/pet/pet-1/weight'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(WeightChart), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.byTooltip('Delete weight entry'), findsNWidgets(3));
  });

  testWidgets('FW-12 unit switch calls setWeightUnitPreferenceProvider', (
    tester,
  ) async {
    WeightUnit? saved;
    await tester.pumpWidget(
      buildApp(
        entries: [
          _entry('w1', DateTime(2026, 1, 1), 10),
          _entry('w2', DateTime(2026, 2, 1), 11),
        ],
        initialLocation: '/pet/pet-1/weight',
        extraOverrides: [
          weightUnitPreferenceProvider.overrideWith((ref) => WeightUnit.kg),
          setWeightUnitPreferenceProvider.overrideWith((ref) {
            return (unit) async {
              saved = unit;
            };
          }),
        ],
      ),
    );
    await tester.pump();
    await tester.tap(find.text('lb'));
    await tester.pump();
    expect(saved, WeightUnit.lb);
  });

  testWidgets('footer opens record weight sheet', (tester) async {
    await tester.pumpWidget(
      buildApp(entries: const [], initialLocation: '/pet/pet-1/weight'),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('weight_tracking_add_footer')));
    await tester.pumpAndSettle();

    expect(find.text('Record weight'), findsWidgets);
  });
}
