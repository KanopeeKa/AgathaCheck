import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/health_entry_form_screen.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/widgets/health_events_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _TwoPetsNotifier extends PetListNotifier {
  @override
  Future<List<Pet>> build() async => const [
    Pet(id: 'p1', name: 'Rex', species: 'Dog'),
  ];
}

class _FakeHealthEntriesNotifier extends HealthEntriesNotifier {
  _FakeHealthEntriesNotifier(this._entries);
  final List<HealthEntry> _entries;

  @override
  Future<List<HealthEntry>> build() async => _entries;
}

HealthEntry _entry(String id, HealthEntryType type) => HealthEntry(
  id: id,
  petId: 'p1',
  name: 'Entry $id',
  type: type,
  frequency: HealthFrequency.monthly,
  startDate: DateTime(2025, 1, 1),
  nextDueDate: DateTime(2025, 2, 1),
);

void main() {
  testWidgets('health events section excludes care and other types', (
    WidgetTester tester,
  ) async {
    final entries = [
      _entry('h1', HealthEntryType.medication),
      _entry('o1', HealthEntryType.familyEvent),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthEntriesNotifierProvider.overrideWith(
            () => _FakeHealthEntriesNotifier(entries),
          ),
          apiBaseUrlProvider.overrideWithValue('http://test.local'),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: HealthEventsSection(petId: 'p1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Health Events'));
    await tester.pumpAndSettle();

    expect(find.text('Entry h1'), findsOneWidget);
    expect(find.text('Entry o1'), findsNothing);
  });

  testWidgets('pet profile health add restricts types to health events only', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/pet/p1',
      routes: [
        GoRoute(
          path: '/pet/:petId',
          builder: (context, state) => Scaffold(
            body: HealthEventsSection(petId: state.pathParameters['petId']!),
          ),
        ),
        GoRoute(
          path: '/pet/:petId/health/add',
          builder: (context, state) => HealthEntryFormScreen(
            petId: state.pathParameters['petId']!,
            allowedTypes: kHealthEventTypes.toList(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          petListProvider.overrideWith(_TwoPetsNotifier.new),
          healthEntriesNotifierProvider.overrideWith(
            () => _FakeHealthEntriesNotifier([]),
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
    await tester.pumpAndSettle();

    await tester.tap(find.text('Health Events'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add_health_event_button')));
    await tester.pumpAndSettle();

    expect(find.text('Medication'), findsOneWidget);
    expect(find.text('Care event'), findsNothing);
    expect(find.text('Other'), findsNothing);
  });
}
