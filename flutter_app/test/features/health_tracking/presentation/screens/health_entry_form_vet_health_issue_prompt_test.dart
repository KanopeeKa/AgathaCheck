import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_planning_mode.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_setting.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';
import 'package:pet_profile_app/features/health_tracking/domain/usecases/create_health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/usecases/get_health_entries.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/controllers/health_entry_form_controller.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/health_entry_form_screen.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _TwoPetsNotifier extends PetListNotifier {
  @override
  Future<List<Pet>> build() async => const [
    Pet(id: 'p1', name: 'Rex', species: 'Dog'),
  ];
}

class _EmptyHealthEntriesNotifier extends HealthEntriesNotifier {
  @override
  Future<List<HealthEntry>> build() async => [];
}

class _RecordingHealthRepository implements HealthRepository {
  HealthEntry? lastCreated;

  @override
  Future<HealthEntry> createEntry(HealthEntry entry) async {
    lastCreated = entry;
    return entry.copyWith(id: 'created-entry');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows health-issue prompt after unplanned vet save', (
    WidgetTester tester,
  ) async {
    final repository = _RecordingHealthRepository();
    final router = GoRouter(
      initialLocation: '/pet/p1/health/add',
      routes: [
        GoRoute(
          path: '/pet/:petId/health/add',
          builder: (context, state) =>
              HealthEntryFormScreen(petId: state.pathParameters['petId']),
        ),
        GoRoute(
          path: '/pet/:petId',
          builder: (context, state) =>
              Scaffold(body: Text('Pet ${state.pathParameters['petId']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          petListProvider.overrideWith(_TwoPetsNotifier.new),
          healthEntriesNotifierProvider.overrideWith(
            _EmptyHealthEntriesNotifier.new,
          ),
          createHealthEntryProvider.overrideWithValue(
            CreateHealthEntry(repository),
          ),
          getHealthEntriesProvider.overrideWithValue(
            GetHealthEntries(repository),
          ),
          apiBaseUrlProvider.overrideWithValue('http://test.local'),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final params = HealthEntryFormParams(petId: 'p1');
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HealthEntryFormScreen)),
    );
    final controller = container.read(
      healthEntryFormControllerProvider(params).notifier,
    );
    controller.setCareFamily(CareFamily.wellnessReview);
    controller.setCareSetting(CareSetting.vet);
    controller.setCarePlanning(CarePlanningMode.unplanned);

    await tester.enterText(
      find.byKey(const Key('health_name_field')),
      'Emergency visit',
    );
    final completedField = find.bySemanticsLabel(RegExp(r'Completed on:'));
    await _scrollTo(tester, completedField);
    await tester.tap(completedField);
    await tester.pumpAndSettle();
    final ok = find.widgetWithText(TextButton, 'OK');
    if (ok.evaluate().isNotEmpty) {
      await tester.tap(ok);
    } else {
      await tester.tap(find.text('OK'));
    }
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.byKey(const Key('save_health_entry_button')));
    await tester.tap(find.byKey(const Key('save_health_entry_button')));
    await tester.pumpAndSettle();

    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      await tester.tap(find.text('Keep active'));
      await tester.pumpAndSettle();
    }

    expect(
      find.text('Was this visit related to a health issue?'),
      findsOneWidget,
    );
    expect(repository.lastCreated?.careSetting, CareSetting.vet);
    expect(repository.lastCreated?.carePlanning, CarePlanningMode.unplanned);

    await tester.tap(
      find.byKey(const Key('vet_health_issue_prompt_dismiss')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pet p1'), findsOneWidget);
  });
}
