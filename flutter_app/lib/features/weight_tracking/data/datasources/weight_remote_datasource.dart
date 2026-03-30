import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weight_entry_model.dart';

abstract class WeightRemoteDataSource {
  Future<List<WeightEntryModel>> getEntries(String petId, String token);
  Future<WeightEntryModel> createEntry(WeightEntryModel entry, String token);
  Future<WeightEntryModel> updateEntry(WeightEntryModel entry, String token);
  Future<void> deleteEntry(int id, String token);
  Future<WeightEntryModel?> getLatestWeight(String petId, String token);
}

class WeightRemoteDataSourceImpl implements WeightRemoteDataSource {
  WeightRemoteDataSourceImpl({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  @override
  Future<List<WeightEntryModel>> getEntries(String petId, String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/weight-entries?pet_id=$petId'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load weight entries');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => WeightEntryModel.fromJson(json)).toList();
  }

  @override
  Future<WeightEntryModel> createEntry(WeightEntryModel entry, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/weight-entries'),
      headers: _headers(token),
      body: jsonEncode(entry.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create weight entry');
    }
    return WeightEntryModel.fromJson(jsonDecode(response.body));
  }

  @override
  Future<WeightEntryModel> updateEntry(WeightEntryModel entry, String token) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/weight-entries/${entry.id}'),
      headers: _headers(token),
      body: jsonEncode(entry.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update weight entry');
    }
    return WeightEntryModel.fromJson(jsonDecode(response.body));
  }

  @override
  Future<void> deleteEntry(int id, String token) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/weight-entries/$id'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete weight entry');
    }
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
    if (response.statusCode != 200) {
      throw Exception('Failed to load latest weight');
    }
    return WeightEntryModel.fromJson(jsonDecode(response.body));
  }
}
