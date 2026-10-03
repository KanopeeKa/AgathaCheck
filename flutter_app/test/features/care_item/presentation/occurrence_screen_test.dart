import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

Map<String, dynamic> detail({
  String status = 'pending',
  String occStatus = 'due',
  String family = 'parasite_prevention',
  String? completedOn,
  Map<String, dynamic>? lastAction,
}) => {
  'occurrence': {
    'id': 'occ-1',
    'scheduled_date': '2026-06-10',
    'scheduled_time': null,
    'status': status,
    'occurrence_status': occStatus,
    'completed_on': completedOn,
    'origin': 'computed',
    'notes': '',
  },
  'entry': {
    'id': 'entry-1',
    'pet_id': 'pet-1',
    'name': 'Flea',
    'care_family': family,
    'recurrence_anchor': 'from_completion',
    'late_completion_choice': null,
    'status': 'active',
    'as_of': {
      'date': '2026-06-10',
      'time': '09:00',
      'timezone': 'Europe/Paris',
    },
  },
  'last_action': lastAction,
};

class _Server {
  _Server(this.reads);

  final List<Object> reads;
  final List<http.Request> requests = [];
  int _read = 0;

  late final http.Client client = MockClient((request) async {
    requests.add(request);
    if (request.method == 'GET') {
      final answer = reads[_read < reads.length ? _read++ : reads.length - 1];
      if (answer is int) return http.Response('{"error":"x"}', answer);
      return http.Response(json.encode(answer), 200);
    }
    return http.Response(json.encode({'undo_token': 'u'}), 200);
  });
}

Widget _wrap(_Server server, {String? focus}) => ProviderScope(
  overrides: [careItemHttpClientProvider.overrideWithValue(server.client)],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: OccurrenceScreen(
      petId: 'pet-1',
      entryId: 'entry-1',
      occurrenceId: 'occ-1',
      focus: focus,
    ),
  ),
);

void main() {
  testWidgets('open: Done completes with the chosen day, then reloads', (
    tester,
  ) async {
    final server = _Server([
      detail(),
      detail(status: 'completed', occStatus: 'done', completedOn: '2026-06-10'),
    ]);
    await tester.pumpWidget(_wrap(server));
    await tester.pumpAndSettle();

    expect(find.text('Mark Flea as done'), findsOneWidget);
    expect(find.byKey(const Key('occurrence_skip')), findsOneWidget);
    expect(find.byKey(const Key('occurrence_change_date')), findsOneWidget);
    await tester.tap(find.byKey(const Key('occurrence_done')));
    await tester.pumpAndSettle();

    final post = server.requests.firstWhere((r) => r.method == 'POST');
    expect(post.url.path, endsWith('/occurrences/occ-1/complete'));
    expect(json.decode(post.body)['completed_on'], '2026-06-10');
    expect(find.byKey(const Key('occurrence_done')), findsNothing);
  });

  testWidgets('weigh-in: Done stays disabled until a weight is entered', (
    tester,
  ) async {
    final server = _Server([detail(family: 'weight_monitoring')]);
    await tester.pumpWidget(_wrap(server, focus: 'weight'));
    await tester.pumpAndSettle();

    FilledButton done() =>
        tester.widget(find.byKey(const Key('occurrence_done')));
    expect(done().onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('occurrence_field_weight')),
      '12.4',
    );
    await tester.pump();
    expect(done().onPressed, isNotNull);
  });

  testWidgets('completed: Undo names a date change', (tester) async {
    final server = _Server([
      detail(
        status: 'completed',
        occStatus: 'done',
        completedOn: '2026-06-09',
        lastAction: {
          'type': 'completion_date_changed',
          'occurrence_id': 'occ-1',
        },
      ),
    ]);
    await tester.pumpWidget(_wrap(server));
    await tester.pumpAndSettle();
    expect(find.text('Undo date change'), findsOneWidget);
    expect(
      find.byKey(const Key('occurrence_field_completed_on')),
      findsOneWidget,
    );
  });

  testWidgets('closed not recorded: Record as done', (tester) async {
    final server = _Server([
      detail(status: 'skipped', occStatus: 'not_recorded'),
    ]);
    await tester.pumpWidget(_wrap(server));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('occurrence_record')));
    await tester.pumpAndSettle();
    final post = server.requests.firstWhere((r) => r.method == 'POST');
    expect(post.url.path, endsWith('/occurrences/occ-1/record'));
  });

  testWidgets('OS-5 a removed occurrence shows the gone state and a link', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_Server([404])));
    await tester.pumpAndSettle();
    expect(find.text('This date no longer exists'), findsOneWidget);
    expect(find.text('About this care item'), findsOneWidget);
  });
}
