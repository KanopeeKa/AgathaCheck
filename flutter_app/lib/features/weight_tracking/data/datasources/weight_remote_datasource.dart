import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/utils/calendar_date.dart';
import '../../domain/entities/weight_fulfilment_candidates.dart';
import '../../domain/entities/weight_overview.dart';
import '../../domain/entities/weight_write_outcomes.dart';
import '../models/weight_entry_model.dart';
import '../weight_api_exception.dart';
import '../weight_api_parsers.dart';

abstract class WeightRemoteDataSource {
  Future<List<WeightEntryModel>> getEntries(String petId, String token);
  Future<WeightEntryModel> createEntry(WeightEntryModel entry, String token);
  Future<WeightEntryModel> updateEntry(WeightEntryModel entry, String token);
  Future<WeightDeleteOutcome> deleteEntry(String id, String token);
  Future<WeightEntryModel?> getLatestWeight(String petId, String token);
  Future<WeightOverview> getOverview(String petId, String token);
  Future<WeightFulfilmentCandidates> getFulfilmentCandidates(
    String petId,
    DateTime date,
    String token,
  );
  Future<WeightSaveOutcome> createEntryWithFulfilment(
    WeightEntryModel entry,
    String fulfilsOccurrenceId,
    String token,
  );
  Future<WeightSaveOutcome> fulfilEntry(
    String weightEntryId,
    String occurrenceId,
    String token,
  );
  Future<void> scheduleUndo(String careEntryId, String undoToken, String token);
}

class WeightRemoteDataSourceImpl implements WeightRemoteDataSource {
  WeightRemoteDataSourceImpl({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Never _throwForResponse(http.Response response) {
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>?;
    } catch (_) {}
    final code = body?['code']?.toString();
    throw WeightApiException(
      response.statusCode,
      code,
      body?['error']?.toString(),
    );
  }

  @override
  Future<List<WeightEntryModel>> getEntries(String petId, String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/weight-entries?pet_id=$petId'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) _throwForResponse(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => WeightEntryModel.fromJson(json)).toList();
  }

  @override
  Future<WeightOverview> getOverview(String petId, String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/weight-entries/overview?pet_id=$petId'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) _throwForResponse(response);
    return parseWeightOverview(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<WeightFulfilmentCandidates> getFulfilmentCandidates(
    String petId,
    DateTime date,
    String token,
  ) async {
    final dateStr = toCalendarDateString(calendarDateOnly(date));
    final uri = Uri.parse(
      '$baseUrl/api/weight-entries/fulfilment-candidates',
    ).replace(queryParameters: {'pet_id': petId, 'date': dateStr});
    final response = await _client.get(uri, headers: _headers(token));
    if (response.statusCode != 200) _throwForResponse(response);
    return parseFulfilmentCandidates(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<WeightEntryModel> createEntry(
    WeightEntryModel entry,
    String token,
  ) async {
    final outcome = await _postEntry(entry, token, fulfilsOccurrenceId: null);
    return WeightEntryModel.fromEntity(outcome.entry);
  }

  Future<WeightSaveOutcome> _postEntry(
    WeightEntryModel entry,
    String token, {
    String? fulfilsOccurrenceId,
  }) async {
    final body = entry.toJson();
    if (fulfilsOccurrenceId != null) {
      body['fulfils_occurrence_id'] = fulfilsOccurrenceId;
    }
    final response = await _client.post(
      Uri.parse('$baseUrl/api/weight-entries'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    if (response.statusCode != 201) _throwForResponse(response);
    return parseWeightSaveResponse(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<WeightSaveOutcome> createEntryWithFulfilment(
    WeightEntryModel entry,
    String fulfilsOccurrenceId,
    String token,
  ) => _postEntry(entry, token, fulfilsOccurrenceId: fulfilsOccurrenceId);

  @override
  Future<WeightSaveOutcome> fulfilEntry(
    String weightEntryId,
    String occurrenceId,
    String token,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/weight-entries/$weightEntryId/fulfil'),
      headers: _headers(token),
      body: jsonEncode({'occurrence_id': occurrenceId}),
    );
    if (response.statusCode != 200) _throwForResponse(response);
    return parseWeightSaveResponse(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<WeightEntryModel> updateEntry(
    WeightEntryModel entry,
    String token,
  ) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/weight-entries/${entry.id}'),
      headers: _headers(token),
      body: jsonEncode(entry.toJson()),
    );
    if (response.statusCode != 200) _throwForResponse(response);
    return WeightEntryModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<WeightDeleteOutcome> deleteEntry(String id, String token) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/weight-entries/$id'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) _throwForResponse(response);
    return parseWeightDeleteResponse(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<WeightEntryModel?> getLatestWeight(String petId, String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/weight-entries/latest?pet_id=$petId'),
      headers: _headers(token),
    );
    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) _throwForResponse(response);
    return WeightEntryModel.fromJson(jsonDecode(response.body));
  }

  @override
  Future<void> scheduleUndo(
    String careEntryId,
    String undoToken,
    String token,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/health-entries/$careEntryId/schedule/undo'),
      headers: _headers(token),
      body: jsonEncode({'undo_token': undoToken}),
    );
    if (response.statusCode != 200) _throwForResponse(response);
  }
}
