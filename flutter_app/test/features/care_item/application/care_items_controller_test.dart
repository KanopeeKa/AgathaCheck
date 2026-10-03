import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/care_item/data/care_item_wire.dart';

import 'care_api_fixtures.dart';

void main() {
  late RecordingClient recorder;
  late ProviderContainer container;
  final responses = <String, Object>{};

  setUp(() {
    responses.clear();
    recorder = RecordingClient((request) {
      final answer = responses['${request.method} ${request.url.path}'];
      if (answer == null) return jsonResponse({'error': 'not found'}, 404);
      return jsonResponse(answer);
    });
    container = ProviderContainer(
      overrides: [
        careItemHttpClientProvider.overrideWithValue(recorder.client),
      ],
    );
  });

  tearDown(() => container.dispose());

  CareItemsController controller([String? petId]) =>
      container.read(careItemsControllerProvider(petId).notifier);
  CareItemsState state([String? petId]) =>
      container.read(careItemsControllerProvider(petId));

  final nextMonth = careItemJson(
    id: 'entry-1',
    open: [
      {
        'id': 'next-2',
        'scheduled_date': '2026-08-10',
        'status': 'coming_up',
        'origin': 'computed',
      },
    ],
  );

  test('refresh loads every care item of the pet in one request', () async {
    responses['GET /api/health-entries'] = [
      careItemJson(id: 'a'),
      careItemJson(id: 'b', anchor: 'from_due_date'),
    ];
    await controller('pet-1').refresh();
    expect(state('pet-1').items.keys, ['a', 'b']);
    expect(state('pet-1').items['b']!.isFixedSchedule, isTrue);
    expect(recorder.requests.single.url.queryParameters, {'pet_id': 'pet-1'});
  });

  test(
    'a command result with the item replaces it without a request',
    () async {
      responses['GET /api/health-entries'] = [careItemJson(id: 'entry-1')];
      await controller().refresh();
      final before = recorder.requests.length;

      await controller().applyResult(
        CareCommandResult(
          entryId: 'entry-1',
          schedule: careItemScheduleFromJson(nextMonth),
        ),
      );
      expect(state().items['entry-1']!.openOccurrences.single.id, 'next-2');
      expect(recorder.requests.length, before);
    },
  );

  test('a command result without the item reloads that item only', () async {
    responses['GET /api/health-entries'] = [careItemJson(id: 'entry-1')];
    await controller().refresh();
    responses['GET /api/health-entries/entry-1'] = nextMonth;

    await controller().applyResult(const CareCommandResult(entryId: 'entry-1'));
    expect(state().items['entry-1']!.openOccurrences.single.id, 'next-2');
    expect(recorder.requests.last.url.path, '/api/health-entries/entry-1');
  });

  test('an item that no longer exists is dropped on reload', () async {
    responses['GET /api/health-entries'] = [careItemJson(id: 'entry-1')];
    await controller().refresh();
    await controller().reloadItem('entry-1');
    expect(state().items, isEmpty);
  });

  test('a pet-scoped controller ignores another pet\'s item', () async {
    await controller('pet-1').applyResult(
      CareCommandResult(
        entryId: 'other',
        schedule: careItemScheduleFromJson(
          careItemJson(id: 'other', petId: 'pet-2'),
        ),
      ),
    );
    expect(state('pet-1').items, isEmpty);
  });

  test('a failed refresh keeps the items and reports the failure', () async {
    responses['GET /api/health-entries'] = [careItemJson(id: 'entry-1')];
    await controller().refresh();
    responses.remove('GET /api/health-entries');
    await controller().refresh();
    expect(state().items.keys, ['entry-1']);
    expect(state().failure, isA<CareNotOpenFailure>());
    expect(state().loading, isFalse);
  });
}
