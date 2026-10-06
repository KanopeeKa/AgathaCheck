import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/care_item/application/care_stack_feedback.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/care_item/data/care_item_wire.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/occurrence/occurrence_blocks.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('closed Not recorded: no tick, record sheet and confirm skip', (
    tester,
  ) async {
    final server = _Server();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          careItemHttpClientProvider.overrideWithValue(server.client),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final d = occurrenceDetailFromJson(
                  detail(
                    status: 'skipped',
                    occStatus: 'not_recorded',
                    closeReason: 'not_recorded',
                    scheduledDate: '2026-09-30',
                  ),
                );
                return OccurrenceBlocks(detail: d, onChanged: () async {});
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('occurrence_done')), findsNothing);
    expect(find.byKey(const Key('occurrence_skip')), findsNothing);
    expect(find.byKey(const Key('occurrence_record')), findsOneWidget);
    expect(find.byKey(const Key('occurrence_confirm_skip')), findsOneWidget);

    await tester.tap(find.byKey(const Key('occurrence_record')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('record_as_given_sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('record_as_given_confirm')));
    await tester.pumpAndSettle();
    final recordPost = server.requests.firstWhere(
      (r) => r.method == 'POST' && r.url.path.endsWith('/record'),
    );
    expect(recordPost.url.path, endsWith('/occurrences/occ-1/record'));
  });

  test('full bulk stack snackbar uses count', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final message = careStackSuccessMessage(
      l,
      done: true,
      result: const CareCommandResult(
        entryId: 'e',
        resolvedGiven: ['a', 'b', 'c'],
      ),
      itemName: 'Meds',
    );
    expect(message, '3 marked done');
  });

  test('partial bulk stack snackbar lists ignored count', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final message = careStackSuccessMessage(
      l,
      done: true,
      result: const CareCommandResult(
        entryId: 'e',
        resolvedGiven: ['a', 'b'],
        ignoredIds: ['c'],
      ),
      itemName: 'Meds',
    );
    expect(message, '2 marked done · 1 already closed');
  });

  test(
    'occurrence detail parses scheduled_date as YYYY-MM-DD calendar day',
    () {
      final d = occurrenceDetailFromJson(
        detail(
          status: 'skipped',
          occStatus: 'not_recorded',
          closeReason: 'not_recorded',
          scheduledDate: '2026-09-30',
        ),
      );
      expect(d.occurrence.date, DateTime(2026, 9, 30));
      expect(d.occurrence.isClosedNotRecorded, isTrue);
    },
  );
}

class _Server {
  final List<http.Request> requests = [];

  late final http.Client client = MockClient((request) async {
    requests.add(request);
    return http.Response(json.encode({'undo_token': 'u'}), 200);
  });
}

Map<String, dynamic> detail({
  required String status,
  required String occStatus,
  String? closeReason,
  required String scheduledDate,
}) => {
  'occurrence': {
    'id': 'occ-1',
    'scheduled_date': scheduledDate,
    'scheduled_time': '08:00',
    'status': status,
    'occurrence_status': occStatus,
    'close_reason': closeReason,
    'completed_on': null,
    'origin': 'schedule',
    'notes': '',
  },
  'entry': {
    'id': 'entry-1',
    'pet_id': 'pet-1',
    'name': 'Weekly antibiotic',
    'care_family': 'medication',
    'recurrence_anchor': 'from_due_date',
    'late_completion_choice': null,
    'status': 'active',
    'as_of': {
      'date': '2026-10-04',
      'time': '12:00',
      'timezone': 'Europe/Paris',
    },
  },
  'last_action': null,
};
