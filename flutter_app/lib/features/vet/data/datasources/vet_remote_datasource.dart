import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/vet_model.dart';

abstract class VetRemoteDataSource {
  Future<List<VetModel>> getAllVets();
  Future<VetModel?> getVet(String id);
  Future<VetModel> createVet(VetModel vet);
  Future<VetModel> updateVet(VetModel vet);
  Future<void> deleteVet(String id);
}

class VetRemoteDataSourceImpl implements VetRemoteDataSource {
  VetRemoteDataSourceImpl({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<List<VetModel>> getAllVets() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/vets'));
    _checkResponse(response);
    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map((e) => VetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<VetModel?> getVet(String id) async {
    final response = await _client.get(Uri.parse('$baseUrl/api/vets/$id'));
    if (response.statusCode == 404) return null;
    _checkResponse(response);
    return VetModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<VetModel> createVet(VetModel vet) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/vets'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(vet.toJson()),
    );
    _checkResponse(response);
    return VetModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<VetModel> updateVet(VetModel vet) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/vets/${vet.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(vet.toJson()),
    );
    _checkResponse(response);
    return VetModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteVet(String id) async {
    final response =
        await _client.delete(Uri.parse('$baseUrl/api/vets/$id'));
    _checkResponse(response);
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 400) {
      final body = response.body;
      String message;
      try {
        final decoded = json.decode(body) as Map<String, dynamic>;
        message = decoded['error'] as String? ?? 'Unknown error';
      } catch (_) {
        message = 'HTTP ${response.statusCode}';
      }
      throw Exception(message);
    }
  }
}
