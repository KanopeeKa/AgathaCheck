import 'dart:convert';

import 'package:http/http.dart' as http;

/// A 4xx/5xx answer from a care route, with the server's stable `code`.
class CareHttpException implements Exception {
  const CareHttpException(this.statusCode, {this.code, this.message});

  final int statusCode;
  final String? code;
  final String? message;

  @override
  String toString() =>
      'CareHttpException($statusCode${code == null ? '' : ', $code'})';
}

/// HTTP calls for care commands and occurrence reads. The [client] carries
/// authentication (it is the app's authenticated client, injected at
/// composition).
class CareItemRemoteDataSource {
  CareItemRemoteDataSource({required this.client, required this.baseUrl});

  final http.Client client;
  final String baseUrl;

  static const _json = {'Content-Type': 'application/json'};

  Uri _entries(String path) => Uri.parse('$baseUrl/api/health-entries$path');

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic>? body;
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } on FormatException {
      body = null;
    }
    if (response.statusCode >= 400) {
      throw CareHttpException(
        response.statusCode,
        code: body?['code'] as String?,
        message: body?['error'] as String?,
      );
    }
    return body ?? const {};
  }

  Future<List<Map<String, dynamic>>> getCareItems({String? petId}) async {
    final uri = _entries(
      '',
    ).replace(queryParameters: petId == null ? null : {'pet_id': petId});
    final response = await client.get(uri);
    if (response.statusCode >= 400) _decode(response);
    return (json.decode(response.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getCareItem(String entryId) async {
    return _decode(await client.get(_entries('/$entryId')));
  }

  Future<Map<String, dynamic>> getOccurrence(
    String entryId,
    String occurrenceId,
  ) async {
    return _decode(
      await client.get(_entries('/$entryId/occurrences/$occurrenceId')),
    );
  }

  Future<Map<String, dynamic>> postComplete(
    String entryId,
    String occurrenceId,
    Map<String, dynamic> body,
  ) async {
    return _decode(
      await client.post(
        _entries('/$entryId/occurrences/$occurrenceId/complete'),
        headers: _json,
        body: json.encode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> postCompleteWeight(
    String petId,
    String entryId,
    String occurrenceId,
    Map<String, dynamic> body,
  ) async {
    return _decode(
      await client.post(
        Uri.parse(
          '$baseUrl/api/pets/$petId/care-rhythms/$entryId/occurrences/$occurrenceId/complete-weight',
        ),
        headers: _json,
        body: json.encode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> patchOccurrence(
    String entryId,
    String occurrenceId,
    Map<String, dynamic> body,
  ) async {
    return _decode(
      await client.patch(
        _entries('/$entryId/occurrences/$occurrenceId'),
        headers: _json,
        body: json.encode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> postUndo(
    String entryId,
    String? undoToken,
  ) async {
    return _decode(
      await client.post(
        _entries('/$entryId/schedule/undo'),
        headers: _json,
        body: json.encode({if (undoToken != null) 'undo_token': undoToken}),
      ),
    );
  }
}
