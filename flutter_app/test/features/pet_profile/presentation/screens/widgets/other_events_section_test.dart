import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/other_event_form_screen.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/widgets/other_events_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _FakeHealthEntriesNotifier extends HealthEntriesNotifier {
  _FakeHealthEntriesNotifier(this._entries);
  final List<HealthEntry> _entries;

  @override
  Future<List<HealthEntry>> build() async => _entries;
}

HealthEntry _otherEntry(String id, String petId, HealthEntryType type) =>
    HealthEntry(
      id: id,
      petId: petId,
      name: 'Event $id',
      type: type,
      frequency: HealthFrequency.once,
      startDate: DateTime(2025, 6, 1),
      nextDueDate: DateTime(2025, 6, 1),
    );

void main() {
  testWidgets('Other events section lists only care and other types', (
    WidgetTester tester,
  ) async {
    final entries = [
      _otherEntry('h1', 'p1', HealthEntryType.medication),
      _otherEntry('o1', 'p1', HealthEntryType.familyEvent),
      _otherEntry('o2', 'p1', HealthEntryType.procedure),
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
          home: Scaffold(body: OtherEventsSection(petId: 'p1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Other events'));
    await tester.pumpAndSettle();

    expect(find.text('Event o1'), findsOneWidget);
    expect(find.text('Event o2'), findsOneWidget);
    expect(find.text('Event h1'), findsNothing);
  });

  testWidgets('add other event navigates to simplified form', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/pet/p1',
      routes: [
        GoRoute(
          path: '/pet/:petId',
          builder: (context, state) => Scaffold(
            body: OtherEventsSection(petId: state.pathParameters['petId']!),
          ),
        ),
        GoRoute(
          path: '/pet/:petId/other/add',
          builder: (context, state) =>
              OtherEventFormScreen(petId: state.pathParameters['petId']!),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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

    await tester.tap(find.text('Other events'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add_other_event_button')));
    await tester.pumpAndSettle();

    expect(find.byType(OtherEventFormScreen), findsOneWidget);
    expect(find.text('Care event'), findsOneWidget);
    expect(find.text('Medication'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<HealthEntryType>));
    await tester.pumpAndSettle();
    expect(find.text('Other'), findsOneWidget);
  });
}
