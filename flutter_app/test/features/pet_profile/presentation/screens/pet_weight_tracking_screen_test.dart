import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'package:pet_profile_app/features/pet_profile/presentation/screens/pet_weight_tracking_screen.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/widgets/weight_chart.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_entry.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/providers/weight_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

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

WeightEntry _entry(String id, DateTime date, double weight) =>
    WeightEntry(id: id, petId: 'pet-1', date: date, weight: weight);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp({
    required List<WeightEntry> entries,
    required String initialLocation,
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
              PetWeightTrackingScreen(petId: state.pathParameters['petId']!),
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
        weightEntriesNotifierProvider.overrideWith(
          () => _FakeWeightEntriesNotifier(entries),
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

  testWidgets('shows title, back navigation, and empty state', (
    tester,
  ) async {
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
    expect(find.byKey(const Key('weight_tracking_add_app_bar')), findsOneWidget);
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
    expect(find.byKey(const Key('weight_tracking_add_footer')), findsOneWidget);
  });

  testWidgets('hides the chart but lists a single entry', (tester) async {
    final entries = [_entry('w1', DateTime(2026, 1, 1), 10.0)];
    await tester.pumpWidget(
      buildApp(entries: entries, initialLocation: '/pet/pet-1/weight'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(WeightChart), findsNothing);
    expect(find.byTooltip('Delete weight entry'), findsOneWidget);
  });

  testWidgets('footer add button opens the entry sheet', (tester) async {
    await tester.pumpWidget(
      buildApp(entries: const [], initialLocation: '/pet/pet-1/weight'),
    );
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('weight_tracking_add_footer')));
    await tester.tap(find.byKey(const Key('weight_tracking_add_footer')));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
  });
}
