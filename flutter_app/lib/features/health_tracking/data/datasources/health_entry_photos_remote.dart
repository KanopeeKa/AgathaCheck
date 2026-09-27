import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'health_remote_response.dart';
import '../models/health_event_photo.dart';

Future<List<EventPhoto>> fetchHealthEntryPhotos({
  required http.Client client,
  required String baseUrl,
  required Map<String, String> headers,
  required void Function(http.Response response) checkResponse,
  required String entryId,
  String? occurrenceId,
}) async {
  final query = occurrenceId != null && occurrenceId.isNotEmpty
      ? {'occurrence_id': occurrenceId}
      : null;
  final uri = Uri.parse('$baseUrl/api/health-entries/$entryId/photos')
      .replace(queryParameters: query);
  final response = await client.get(uri, headers: headers);
  checkResponse(response);
  final list = json.decode(response.body) as List<dynamic>;
  return list
      .map((e) => EventPhoto.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<EventPhoto> postHealthEntryPhoto({
  required http.Client client,
  required String baseUrl,
  required Map<String, String> headers,
  required void Function(http.Response response) checkResponse,
  required String entryId,
  required Uint8List bytes,
  required String filename,
  String caption = '',
  String? occurrenceId,
}) async {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/api/health-entries/$entryId/photos'),
  );
  request.headers.addAll(headers);
  request.files.add(
    http.MultipartFile.fromBytes('photo', bytes, filename: filename),
  );
  if (caption.isNotEmpty) {
    request.fields['caption'] = caption;
  }
  if (occurrenceId != null && occurrenceId.isNotEmpty) {
    request.fields['health_occurrence_id'] = occurrenceId;
  }
  final streamedResponse = await client.send(request);
  final response = await http.Response.fromStream(streamedResponse);
  checkResponse(response);
  return EventPhoto.fromJson(
    json.decode(response.body) as Map<String, dynamic>,
  );
}

Future<void> deleteHealthEntryPhoto({
  required http.Client client,
  required String baseUrl,
  required Map<String, String> headers,
  required void Function(http.Response response) checkResponse,
  required String entryId,
  required String photoId,
}) async {
  final response = await client.delete(
    Uri.parse('$baseUrl/api/health-entries/$entryId/photos/$photoId'),
    headers: headers,
  );
  checkResponse(response);
}
