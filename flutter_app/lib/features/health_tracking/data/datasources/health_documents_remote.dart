import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'health_documents_failure_mapper.dart';
import '../models/health_event_photo.dart';

Future<List<EventPhoto>> fetchHealthEntryPhotosTransport({
  required http.Client client,
  required String baseUrl,
  required String entryId,
  String? occurrenceId,
}) async {
  try {
    final query = occurrenceId != null && occurrenceId.isNotEmpty
        ? {'occurrence_id': occurrenceId}
        : null;
    final uri = Uri.parse(
      '$baseUrl/api/health-entries/$entryId/photos',
    ).replace(queryParameters: query);
    final response = await client.get(uri);
    checkHealthDocumentResponse(response);
    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map((e) => EventPhoto.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    throwHealthDocumentFailure(e, st);
  }
}

Future<EventPhoto> postHealthEntryPhotoTransport({
  required http.Client client,
  required String baseUrl,
  required String entryId,
  required Uint8List bytes,
  required String filename,
  String caption = '',
  String? occurrenceId,
}) async {
  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/health-entries/$entryId/photos'),
    );
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
    checkHealthDocumentResponse(response);
    return EventPhoto.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  } catch (e, st) {
    throwHealthDocumentFailure(e, st);
  }
}

Future<void> deleteHealthEntryPhotoTransport({
  required http.Client client,
  required String baseUrl,
  required String entryId,
  required String photoId,
}) async {
  try {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/health-entries/$entryId/photos/$photoId'),
    );
    checkHealthDocumentResponse(response);
  } catch (e, st) {
    throwHealthDocumentFailure(e, st);
  }
}

Future<List<Map<String, dynamic>>> fetchHealthIssueDocumentsTransport({
  required http.Client client,
  required String baseUrl,
  required String issueId,
}) async {
  try {
    final response = await client.get(
      Uri.parse('$baseUrl/api/health-issues/$issueId/documents'),
    );
    checkHealthDocumentResponse(response);
    final list = json.decode(response.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  } catch (e, st) {
    throwHealthDocumentFailure(e, st);
  }
}

Future<Map<String, dynamic>> postHealthIssueDocumentTransport({
  required http.Client client,
  required String baseUrl,
  required String issueId,
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) async {
  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/health-issues/$issueId/documents'),
    );
    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: filename,
        contentType: mimeType.trim().isEmpty ? null : MediaType.parse(mimeType),
      ),
    );
    final streamed = await client.send(request);
    final response = await http.Response.fromStream(streamed);
    checkHealthDocumentResponse(response);
    return json.decode(response.body) as Map<String, dynamic>;
  } catch (e, st) {
    throwHealthDocumentFailure(e, st);
  }
}

Future<void> deleteHealthIssueDocumentTransport({
  required http.Client client,
  required String baseUrl,
  required String issueId,
  required String documentId,
}) async {
  try {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/health-issues/$issueId/documents/$documentId'),
    );
    checkHealthDocumentResponse(response);
  } catch (e, st) {
    throwHealthDocumentFailure(e, st);
  }
}
