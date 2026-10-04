import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Wire fixtures shaped like `api-reference.md` § Occurrence APIs.

Map<String, dynamic> careItemJson({
  String id = 'entry-1',
  String petId = 'pet-1',
  String family = 'parasite_prevention',
  String anchor = 'from_completion',
  List<Map<String, dynamic>>? open,
}) => {
  'id': id,
  'pet_id': petId,
  'name': 'Flea',
  'care_family': family,
  'recurrence_anchor': anchor,
  'status': 'active',
  'next_due_date': '2026-07-10',
  'open_occurrences':
      open ??
      [
        {
          'id': 'next-1',
          'scheduled_date': '2026-07-10',
          'scheduled_time': null,
          'status': 'coming_up',
          'origin': 'computed',
        },
      ],
  'as_of': {'date': '2026-06-10', 'time': '09:00', 'timezone': 'Europe/Paris'},
  'estimated_next': null,
  'late_completion_choice': null,
};

Map<String, dynamic> commandJson({
  Map<String, dynamic>? entry,
  String? nextChoiceApplied,
  Map<String, dynamic> extra = const {},
}) => {
  'occurrence': {
    'id': 'occ-1',
    'status': 'completed',
    'completed_on': '2026-06-10',
  },
  'entry': entry ?? careItemJson(),
  'next_due_date': '2026-07-10',
  'undo_token': 'undo-1',
  'next_choice_applied': nextChoiceApplied,
  ...extra,
};

/// A [MockClient] that records requests and answers from [handler].
class RecordingClient {
  RecordingClient(this.handler);

  final http.Response Function(http.Request request) handler;
  final List<http.Request> requests = [];

  late final http.Client client = MockClient((request) async {
    requests.add(request);
    return handler(request);
  });

  Map<String, dynamic> body(int index) =>
      json.decode(requests[index].body) as Map<String, dynamic>;
}

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
  json.encode(body),
  status,
  headers: {'content-type': 'application/json'},
);
