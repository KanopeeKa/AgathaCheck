import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pet_profile_app/core/network/auth_http_client.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/care_item/data/care_item_remote_datasource.dart';

import 'care_api_fixtures.dart';

CareCompletionService serviceFor(RecordingClient recorder) =>
    CareCompletionService(
      CareItemRemoteDataSource(client: recorder.client, baseUrl: '/backend'),
    );

CareCompletionRequest request({
  String family = 'parasite_prevention',
  DateTime? completedOn,
  CompletionInputs inputs = const CompletionInputs(),
  CareCommandPath path = CareCommandPath.oneTap,
}) => CareCompletionRequest(
  petId: 'pet-1',
  entryId: 'entry-1',
  occurrenceId: 'occ-1',
  careFamily: family,
  completedOn: completedOn,
  inputs: inputs,
  source: CareCommandSource.careItem,
  path: path,
);

void main() {
  group('complete (§18.6.1, DN-6)', () {
    test(
      'one tap posts complete without next_choice or earlier_choice',
      () async {
        final recorder = RecordingClient(
          (_) => jsonResponse(commandJson(nextChoiceApplied: 'keep')),
        );
        final outcome = await serviceFor(recorder).complete(request());

        expect(
          recorder.requests.single.url.path,
          '/backend/api/health-entries/entry-1/occurrences/occ-1/complete',
        );
        final body = recorder.body(0);
        expect(body.containsKey('next_choice'), isFalse);
        expect(body.containsKey('earlier_choice'), isFalse);
        expect(body.containsKey('completed_on'), isFalse);
        expect(body['source'], 'care_item');
        expect(body['path'], 'one_tap');

        final result = (outcome as CareSucceeded<CareCommandResult>).value;
        expect(result.undoToken, 'undo-1');
        expect(result.nextChoiceApplied, 'keep');
        expect(result.occurrenceId, 'occ-1');
        expect(result.nextDueDate, DateTime(2026, 7, 10));
        expect(result.schedule?.openOccurrences.single.id, 'next-1');
      },
    );

    test('DN-3 sends the chosen date as a calendar day', () async {
      final recorder = RecordingClient((_) => jsonResponse(commandJson()));
      await serviceFor(recorder).complete(
        request(
          completedOn: DateTime(2026, 6, 8),
          path: CareCommandPath.dateSheet,
        ),
      );
      expect(recorder.body(0)['completed_on'], '2026-06-08');
      expect(recorder.body(0)['path'], 'date_sheet');
    });

    test('a weigh-in goes to complete-weight with the weight and day', () async {
      final recorder = RecordingClient(
        (_) => jsonResponse({
          'occurrence': {'id': 'occ-1'},
          'weight_entry': {'weight': 12.4},
          'next_due_date': '2026-07-01',
          'undo_token': 'undo-2',
          'next_choice_applied': null,
        }, 201),
      );
      final outcome = await serviceFor(recorder).complete(
        request(
          family: 'weight_monitoring',
          completedOn: DateTime(2026, 6, 1),
          inputs: const CompletionInputs(weightValue: 12.4),
          path: CareCommandPath.occurrenceScreen,
        ),
      );
      expect(
        recorder.requests.single.url.path,
        '/backend/api/pets/pet-1/care-rhythms/entry-1/occurrences/occ-1/complete-weight',
      );
      expect(recorder.body(0), containsPair('weight', 12.4));
      expect(recorder.body(0), containsPair('date', '2026-06-01'));
      expect(recorder.body(0).containsKey('next_choice'), isFalse);
      final result = (outcome as CareSucceeded<CareCommandResult>).value;
      expect(result.schedule, isNull);
      expect(result.undoToken, 'undo-2');
    });

    test('a weigh-in without a weight is refused locally (DN-2)', () async {
      final recorder = RecordingClient((_) => jsonResponse(commandJson()));
      final outcome = await serviceFor(
        recorder,
      ).complete(request(family: 'weight_monitoring'));
      expect(recorder.requests, isEmpty);
      final failure = (outcome as CareFailed<CareCommandResult>).failure;
      expect(failure, isA<CareValidationFailure>());
      expect((failure as CareValidationFailure).code, 'weight_required');
    });
  });

  group('failures (§18.10, DN-9)', () {
    Future<CareCommandFailure> failWith(http.Response response) async {
      final outcome = await serviceFor(
        RecordingClient((_) => response),
      ).complete(request());
      return (outcome as CareFailed<CareCommandResult>).failure;
    }

    test(
      '409 occurrence_not_open → not open (reload, "Already updated")',
      () async {
        final f = await failWith(
          jsonResponse({'error': 'x', 'code': 'occurrence_not_open'}, 409),
        );
        expect(f, isA<CareNotOpenFailure>());
        expect((f as CareNotOpenFailure).gone, isFalse);
        expect(f.analyticsValue, 'not_open');
      },
    );

    test('404 → occurrence gone', () async {
      final f = await failWith(
        jsonResponse({'error': 'Occurrence not found'}, 404),
      );
      expect(f, isA<CareNotOpenFailure>());
      expect((f as CareNotOpenFailure).gone, isTrue);
    });

    test('400 keeps the server code', () async {
      final f = await failWith(
        jsonResponse({'error': 'x', 'code': 'completed_on_in_future'}, 400),
      );
      expect((f as CareValidationFailure).code, 'completed_on_in_future');
      expect(f.analyticsValue, 'validation');
    });

    test(
      'other 409 → conflict; 500 → unknown; non-JSON body tolerated',
      () async {
        final conflict = await failWith(
          jsonResponse({'error': 'x', 'code': 'undo_stale'}, 409),
        );
        expect((conflict as CareConflictFailure).code, 'undo_stale');
        final unknown = await failWith(http.Response('<html>', 502));
        expect((unknown as CareUnknownFailure).statusCode, 502);
      },
    );

    test('no answer → network', () async {
      final service = serviceFor(
        RecordingClient((_) => throw http.ClientException('offline')),
      );
      final outcome = await service.complete(request());
      expect(
        (outcome as CareFailed<CareCommandResult>).failure,
        isA<CareNetworkFailure>(),
      );
    });

    test('expired session → network', () async {
      final service = serviceFor(
        RecordingClient((_) => throw SessionExpiredException()),
      );
      final outcome = await service.complete(request());
      expect(
        (outcome as CareFailed<CareCommandResult>).failure,
        isA<CareNetworkFailure>(),
      );
    });
  });

  group('occurrence edits and reads', () {
    test(
      'changeCompletionDate patches completed_on alone (D-CSM-034)',
      () async {
        final recorder = RecordingClient(
          (_) => jsonResponse(
            commandJson(
              extra: {
                'id': 'occ-1',
                'moved_next_id': 'next-1',
                'next_unchanged': false,
              },
            ),
          ),
        );
        final outcome = await serviceFor(recorder).changeCompletionDate(
          entryId: 'entry-1',
          occurrenceId: 'occ-1',
          completedOn: DateTime(2026, 6, 8),
        );
        expect(recorder.requests.single.method, 'PATCH');
        expect(recorder.body(0), {'completed_on': '2026-06-08'});
        final result = (outcome as CareSucceeded<CareCommandResult>).value;
        expect(result.movedNextId, 'next-1');
        expect(result.nextUnchanged, isFalse);
      },
    );

    test('undo sends the token', () async {
      final recorder = RecordingClient((_) => jsonResponse(commandJson()));
      await serviceFor(recorder).undo(entryId: 'entry-1', undoToken: 'undo-1');
      expect(
        recorder.requests.single.url.path,
        '/backend/api/health-entries/entry-1/schedule/undo',
      );
      expect(recorder.body(0), {'undo_token': 'undo-1'});
    });

    test('fetchOccurrence parses the occurrence screen read', () async {
      final recorder = RecordingClient(
        (_) => jsonResponse({
          'occurrence': {
            'id': 'occ-1',
            'scheduled_date': '2026-06-05',
            'scheduled_time': null,
            'status': 'completed',
            'occurrence_status': 'done',
            'completed_on': '2026-06-10',
            'origin': 'computed',
            'notes': '',
          },
          'entry': {
            'id': 'entry-1',
            'pet_id': 'pet-1',
            'name': 'Flea',
            'care_family': 'parasite_prevention',
            'recurrence_anchor': 'from_completion',
            'late_completion_choice': null,
            'status': 'active',
            'as_of': {
              'date': '2026-06-10',
              'time': '09:05',
              'timezone': 'Europe/Paris',
            },
          },
          'last_action': {
            'type': 'completion_date_changed',
            'occurrence_id': 'occ-1',
          },
          'linked_weight': {'value': 12.4, 'unit': 'kg'},
        }),
      );
      final outcome = await serviceFor(
        recorder,
      ).fetchOccurrence(entryId: 'entry-1', occurrenceId: 'occ-1');
      final detail = (outcome as CareSucceeded<OccurrenceDetail>).value;
      expect(detail.occurrence.isDone, isTrue);
      expect(detail.occurrence.isOpen, isFalse);
      expect(detail.occurrence.completedOn, DateTime(2026, 6, 10));
      expect(detail.item.isFixedSchedule, isFalse);
      expect(detail.item.asOf.time, '09:05');
      expect(detail.canUndoHere, isTrue);
      expect(detail.lastAction?.isCompletionDateChange, isTrue);
      expect(detail.linkedWeight?.value, 12.4);
    });

    test('fetchOccurrence 404 → gone (OS-5)', () async {
      final recorder = RecordingClient(
        (_) => jsonResponse({'error': 'Occurrence not found'}, 404),
      );
      final outcome = await serviceFor(
        recorder,
      ).fetchOccurrence(entryId: 'entry-1', occurrenceId: 'x');
      final failure = (outcome as CareFailed<OccurrenceDetail>).failure;
      expect((failure as CareNotOpenFailure).gone, isTrue);
    });
  });
}
