import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_profile_app/core/providers/pet_care_sync.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/weight/weight_unit.dart';
import 'package:pet_profile_app/core/weight/weight_unit_preference.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _RecordingPetCareSync implements PetCareSync {
  final List<String> weightChangedPetIds = [];

  @override
  Future<void> weightChanged(String petId) async {
    weightChangedPetIds.add(petId);
  }

  @override
  Future<void> careChanged(String petId) async {}
}

Map<String, dynamic> detail({
  String status = 'pending',
  String occStatus = 'due',
  String family = 'parasite_prevention',
  String? completedOn,
  String? closeReason,
  Map<String, dynamic>? lastAction,
  Map<String, dynamic>? linkedWeight,
  Map<String, dynamic>? skipReason,
}) {
  final payload = {
  'occurrence': {
    'id': 'occ-1',
    'scheduled_date': '2026-06-10',
    'scheduled_time': null,
    'status': status,
    'occurrence_status': occStatus,
    'completed_on': completedOn,
    'close_reason': closeReason,
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
  if (linkedWeight != null) payload['linked_weight'] = linkedWeight;
  if (skipReason != null) payload['skip_reason'] = skipReason;
  return payload;
}

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

Widget _wrap(
  _Server server, {
  String? focus,
  List<Override> extraOverrides = const [],
}) => ProviderScope(
  overrides: [
    careItemHttpClientProvider.overrideWithValue(server.client),
    ...extraOverrides,
  ],
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
      detail(
        status: 'skipped',
        occStatus: 'not_recorded',
        closeReason: 'not_recorded',
      ),
    ]);
    await tester.pumpWidget(_wrap(server));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('occurrence_record')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('record_as_given_confirm')));
    await tester.pumpAndSettle();
    final post = server.requests.firstWhere(
      (r) => r.method == 'POST' && r.url.path.endsWith('/record'),
    );
    expect(post.url.path, endsWith('/occurrences/occ-1/record'));
  });

  testWidgets('FW-13 label uses lb and complete-weight sends unit lb', (
    tester,
  ) async {
    final server = _Server([detail(family: 'weight_monitoring')]);
    await tester.pumpWidget(
      _wrap(
        server,
        focus: 'weight',
        extraOverrides: [
          weightUnitPreferenceProvider.overrideWith((ref) => WeightUnit.lb),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weight (lb)'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('occurrence_field_weight')),
      '22.0',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('occurrence_done')));
    await tester.pumpAndSettle();

    final post = server.requests.firstWhere(
      (r) => r.method == 'POST' && r.url.path.contains('complete-weight'),
    );
    expect(json.decode(post.body)['unit'], 'lb');
    expect(json.decode(post.body)['weight'], 22.0);
  });

  testWidgets('FW-14 weigh-in skip opens reason sheet and sends reason_code', (
    tester,
  ) async {
    final server = _Server([
      detail(family: 'weight_monitoring'),
      detail(status: 'skipped', occStatus: 'skipped', family: 'weight_monitoring'),
    ]);
    await tester.pumpWidget(_wrap(server));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('occurrence_skip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skip_weigh_in_sheet')), findsOneWidget);

    await tester.tap(find.byKey(const Key('skip_weigh_in_reason_could_not_weigh')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('skip_weigh_in_note')), 'Wiggly');
    await tester.tap(find.byKey(const Key('skip_weigh_in_confirm')));
    await tester.pumpAndSettle();

    final post = server.requests.firstWhere(
      (r) => r.method == 'POST' && r.url.path.endsWith('/skip'),
    );
    final body = json.decode(post.body) as Map<String, dynamic>;
    expect(body['reason_code'], 'could_not_weigh');
    expect(body['notes'], 'Wiggly');
  });

  testWidgets('FW-14 non-weigh-in skip does not open the weigh-in sheet', (
    tester,
  ) async {
    final server = _Server([
      detail(),
      detail(status: 'skipped', occStatus: 'skipped'),
    ]);
    await tester.pumpWidget(_wrap(server));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('occurrence_skip')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('skip_weigh_in_sheet')), findsNothing);
  });

  testWidgets('FW-15 completed weigh-in shows weight in user unit and link', (
    tester,
  ) async {
    final server = _Server([
      detail(
        status: 'completed',
        occStatus: 'done',
        completedOn: '2026-06-10',
        family: 'weight_monitoring',
        linkedWeight: const {
          'value': 10.0,
          'unit': 'kg',
          'date': '2026-06-10',
        },
      ),
    ]);
    await tester.pumpWidget(
      _wrap(
        server,
        extraOverrides: [
          weightUnitPreferenceProvider.overrideWith((ref) => WeightUnit.lb),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('22.0 lb'), findsOneWidget);
    expect(find.byKey(const Key('occurrence_see_all_weights')), findsOneWidget);
    expect(find.text('See all weights'), findsOneWidget);
  });

  testWidgets('FW-15 skipped weigh-in shows reason and note', (tester) async {
    final server = _Server([
      detail(
        status: 'skipped',
        occStatus: 'skipped',
        family: 'weight_monitoring',
        skipReason: const {
          'code': 'could_not_weigh',
          'note': 'Too wiggly',
        },
      ),
    ]);
    await tester.pumpWidget(_wrap(server));
    await tester.pumpAndSettle();

    expect(find.text('Skipped · Couldn\'t weigh'), findsOneWidget);
    expect(find.text('Too wiggly'), findsOneWidget);
  });

  testWidgets('FW-16 weigh-in done calls petCareSyncProvider.weightChanged', (
    tester,
  ) async {
    final sync = _RecordingPetCareSync();
    final server = _Server([
      detail(family: 'weight_monitoring'),
      detail(
        status: 'completed',
        occStatus: 'done',
        completedOn: '2026-06-10',
        family: 'weight_monitoring',
      ),
    ]);
    await tester.pumpWidget(
      _wrap(
        server,
        focus: 'weight',
        extraOverrides: [
          petCareSyncProvider.overrideWith((ref) => sync),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('occurrence_field_weight')),
      '12.4',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('occurrence_done')));
    await tester.pumpAndSettle();

    expect(sync.weightChangedPetIds, ['pet-1']);
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
