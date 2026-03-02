import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weight_entry_model.dart';

abstract class WeightRemoteDataSource {
  Future<List<WeightEntryModel>> getEntries(String petId);
  Future<WeightEntryModel> createEntry(WeightEntryModel entry);
  Future<WeightEntryModel> updateEntry(WeightEntryModel entry);
  Future<void> deleteEntry(int id);
  Future<WeightEntryModel?> getLatestWeight(String petId);
}

class WeightRemoteDataSourceImpl implements WeightRemoteDataSource {
  WeightRemoteDataSourceImpl({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<List<WeightEntryModel>> getEntries(String petId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/weight-entries?pet_id=$petId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load weight entries');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => WeightEntryModel.fromJson(json)).toList();
  }

  @override
  Future<WeightEntryModel> createEntry(WeightEntryModel entry) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/weight-entries'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(entry.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create weight entry');
    }
    return WeightEntryModel.fromJson(jsonDecode(response.body));
  }

  @override
  Future<WeightEntryModel> updateEntry(WeightEntryModel entry) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/weight-entries/${entry.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(entry.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update weight entry');
    }
    return WeightEntryModel.fromJson(jsonDecode(response.body));
  }

  @override
  Future<void> deleteEntry(int id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/weight-entries/$id'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete weight entry');
    }
  }

  @override
  Future<WeightEntryModel?> getLatestWeight(String petId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/weight-entries/latest?pet_id=$petId'),
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
