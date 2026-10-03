import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/care_progression_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_care_section/pet_care_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/care_schedule_entries.dart';

class _FakeHealthEntriesNotifier extends HealthEntriesNotifier {
  _FakeHealthEntriesNotifier(this._entries);

  final List<HealthEntry> _entries;
  int refreshes = 0;

  @override
  Future<List<HealthEntry>> build() async => _entries;

  @override
  Future<void> refresh() async {
    refreshes++;
  }
}

Widget _wrap({
  required _FakeHealthEntriesNotifier notifier,
  required List<http.Request> requests,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: SingleChildScrollView(
            child: PetCareSection(
              petId: 'pet-1',
              pet: Pet(id: 'pet-1', name: 'Buddy', species: 'Dog'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/pet/:petId/events',
        builder: (context, state) => const Scaffold(body: Text('All care')),
      ),
      GoRoute(
        path: '/pet/:petId/events/:entryId',
        builder: (context, state) => const Scaffold(body: Text('Care item')),
      ),
    ],
  );
  final client = MockClient((request) async {
    requests.add(request);
    return http.Response(
      json.encode({'undo_token': 'u1', 'next_choice_applied': null}),
      200,
    );
  });

  return ProviderScope(
    overrides: [
      healthEntriesNotifierProvider.overrideWith(() => notifier),
      petCareEstablishmentsProvider.overrideWith(
        (ref, petId) => Future.value(const []),
      ),
      careItemHttpClientProvider.overrideWithValue(client),
    ],
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('renders the agenda: Today, Due soon and a collapsed Upcoming', (
    tester,
  ) async {
    final entries = [
      scheduledEntry(id: 'overdue', name: 'Flea', dueInDays: -2),
      scheduledEntry(id: 'today', name: 'Brush', dueInDays: 0),
      scheduledEntry(id: 'soon', name: 'Groom', dueInDays: 3),
      scheduledEntry(id: 'later', name: 'Rabies', dueInDays: 200),
    ];
    await tester.pumpWidget(
      _wrap(notifier: _FakeHealthEntriesNotifier(entries), requests: []),
    );
    await tester.pumpAndSettle();

    expect(find.text("Buddy's care"), findsOneWidget);
    expect(find.byKey(const Key('care_agenda_today')), findsOneWidget);
    expect(find.byKey(const Key('care_agenda_due_soon')), findsOneWidget);
    expect(find.byKey(const Key('care_agenda_upcoming')), findsOneWidget);
    expect(find.text('Flea'), findsOneWidget);
    expect(find.text('Brush'), findsOneWidget);
    expect(find.text('Groom'), findsOneWidget);
    expect(find.text('Rabies'), findsNothing);
    expect(find.text('Upcoming (1)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('care_agenda_upcoming')));
    await tester.pumpAndSettle();
    expect(find.text('Rabies'), findsOneWidget);
  });

  testWidgets('shows the empty state when there is no care', (tester) async {
    await tester.pumpWidget(
      _wrap(notifier: _FakeHealthEntriesNotifier([]), requests: []),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pet_care_section_empty')), findsOneWidget);
  });

  testWidgets('Done completes today in one request and refreshes (DN-5)', (
    tester,
  ) async {
    final notifier = _FakeHealthEntriesNotifier([
      scheduledEntry(id: 'today', name: 'Brush', dueInDays: 0),
    ]);
    final requests = <http.Request>[];
    await tester.pumpWidget(_wrap(notifier: notifier, requests: requests));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pet_care_action_done_today')));
    await tester.pumpAndSettle();

    expect(requests, hasLength(1));
    expect(
      requests.single.url.path,
      endsWith('/occurrences/today-occ/complete'),
    );
    final body = json.decode(requests.single.body) as Map<String, dynamic>;
    expect(body.containsKey('next_choice'), isFalse);
    expect(notifier.refreshes, 1);
    expect(find.text('Brush done'), findsOneWidget);
  });

  testWidgets('a stack is one row and Done opens the care item (DN-1)', (
    tester,
  ) async {
    final today = careToday();
    final entry = scheduledEntry(
      id: 'pill',
      name: 'Pill',
      fixed: true,
      frequency: HealthFrequency.daily,
      open: [
        OpenOccurrence(
          id: 'y',
          date: today.subtract(const Duration(days: 1)),
          status: CareOccurrenceStatus.notRecorded,
          origin: CareOccurrenceOrigin.schedule,
        ),
        OpenOccurrence(
          id: 't',
          date: today,
          status: CareOccurrenceStatus.due,
          origin: CareOccurrenceOrigin.schedule,
        ),
      ],
    );
    final requests = <http.Request>[];
    await tester.pumpWidget(
      _wrap(notifier: _FakeHealthEntriesNotifier([entry]), requests: requests),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('care_agenda_stack_pill')), findsOneWidget);
    expect(find.text('2 not recorded'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pet_care_action_done_pill')));
    await tester.pumpAndSettle();
    expect(requests, isEmpty);
    expect(find.text('Care item'), findsOneWidget);
  });
}
