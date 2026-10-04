import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/pet_care/pet_care_upcoming_events_section.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/care_schedule_entries.dart';

class _Notifier extends HealthEntriesNotifier {
  _Notifier(this._build);

  final Future<List<HealthEntry>> Function() _build;
  int refreshes = 0;

  @override
  Future<List<HealthEntry>> build() => _build();

  @override
  Future<void> refresh() async => refreshes++;
}

const _pets = [
  Pet(id: 'pet-1', name: 'Buddy', species: 'Dog'),
  Pet(id: 'pet-2', name: 'Misty', species: 'Cat'),
];

Widget _wrap(
  _Notifier notifier, {
  List<http.Request>? requests,
  VoidCallback? onAdd,
}) {
  final client = MockClient((request) async {
    requests?.add(request);
    return http.Response(json.encode({'undo_token': 'u'}), 200);
  });
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: SingleChildScrollView(
            child: PetCareUpcomingEventsSection(pets: _pets, onAddEvent: onAdd),
          ),
        ),
      ),
      GoRoute(
        path: '/pc/events',
        builder: (context, state) => const Scaffold(body: Text('All care')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      healthEntriesNotifierProvider.overrideWith(() => notifier),
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
  testWidgets('shows the orientation line and rows for every pet', (
    tester,
  ) async {
    final notifier = _Notifier(
      () async => [
        scheduledEntry(id: 'a', name: 'Flea', dueInDays: -1),
        scheduledEntry(id: 'b', name: 'Brush', petId: 'pet-2', dueInDays: 0),
        scheduledEntry(id: 'c', name: 'Groom', dueInDays: 4),
      ],
    );
    await tester.pumpWidget(_wrap(notifier));
    await tester.pumpAndSettle();

    expect(find.text('1 overdue · 1 due today'), findsOneWidget);
    expect(find.text('Flea'), findsOneWidget);
    expect(find.text('Brush'), findsOneWidget);
    expect(find.textContaining('Misty'), findsWidgets);
    expect(
      find.byKey(const Key('pet_care_dashboard_care_view_all')),
      findsOneWidget,
    );
  });

  testWidgets('nothing today: one reassuring line, then later care', (
    tester,
  ) async {
    final notifier = _Notifier(
      () async => [scheduledEntry(id: 'c', name: 'Groom', dueInDays: 4)],
    );
    await tester.pumpWidget(_wrap(notifier));
    await tester.pumpAndSettle();
    expect(find.text('Nothing due today'), findsWidgets);
    expect(find.text('Groom'), findsOneWidget);
  });

  testWidgets('no care at all: the illustrated empty state with Add', (
    tester,
  ) async {
    var added = 0;
    await tester.pumpWidget(
      _wrap(_Notifier(() async => []), onAdd: () => added++),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('pet_care_dashboard_empty_care')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('pet_care_dashboard_empty_care_action')),
    );
    expect(added, 1);
  });

  testWidgets('an error is retryable and not shown as empty', (tester) async {
    final notifier = _Notifier(() async => throw Exception('offline'));
    await tester.pumpWidget(_wrap(notifier));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('pet_care_dashboard_empty_care')),
      findsNothing,
    );
    await tester.tap(find.byIcon(Icons.refresh));
    expect(notifier.refreshes, 1);
  });

  testWidgets('Done sends one request; the row changes only after reload', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final notifier = _Notifier(
      () async => [scheduledEntry(id: 'b', name: 'Brush', dueInDays: 0)],
    );
    await tester.pumpWidget(_wrap(notifier, requests: requests));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pet_care_action_done_b')));
    await tester.pumpAndSettle();
    expect(requests, hasLength(1));
    expect(notifier.refreshes, 1);
    // Server-confirmed only: the fake reload returns the same list.
    expect(find.text('Brush'), findsWidgets);
    expect(find.text('Brush done'), findsOneWidget);
  });
}
