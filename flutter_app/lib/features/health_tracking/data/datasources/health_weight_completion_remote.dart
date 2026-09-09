import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/utils/calendar_date.dart';

Future<void> completeWeightOccurrenceRemote({
  required http.Client client,
  required String baseUrl,
  required Map<String, String> headers,
  required void Function(http.Response response) checkResponse,
  required String petId,
  required String entryId,
  required String occurrenceId,
  required double weightKg,
  required DateTime date,
  String notes = '',
  String unit = 'kg',
  String measurementSource = 'guardian',
}) async {
  final response = await client.post(
    Uri.parse(
      '$baseUrl/api/pets/$petId/care-rhythms/$entryId/occurrences/$occurrenceId/complete-weight',
    ),
    headers: headers,
    body: json.encode({
      'weight': weightKg,
      'unit': unit,
      'date': toCalendarDateString(calendarDateOnly(date)),
      'notes': notes,
      'measurement_source': measurementSource,
    }),
  );
  if (response.statusCode != 200 && response.statusCode != 201) {
    checkResponse(response);
  }
}
