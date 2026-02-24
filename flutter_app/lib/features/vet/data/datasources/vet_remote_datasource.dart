import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/vet_model.dart';

/// Abstract interface for the veterinarian remote data source.
///
/// Defines the contract for communicating with the remote API
/// to perform CRUD operations on [VetModel] records.
abstract class VetRemoteDataSource {
  /// Fetches all veterinarians from the remote API.
  Future<List<VetModel>> getAllVets();

  /// Fetches a single veterinarian by [id] from the remote API.
  ///
  /// Returns `null` if the veterinarian is not found.
  Future<VetModel?> getVet(String id);

  /// Creates a new veterinarian via the remote API.
  ///
  /// Returns the created [VetModel] with server-assigned fields.
  Future<VetModel> createVet(VetModel vet);

  /// Updates an existing veterinarian via the remote API.
  ///
  /// Returns the updated [VetModel].
  Future<VetModel> updateVet(VetModel vet);

  /// Deletes the veterinarian with the given [id] via the remote API.
  Future<void> deleteVet(String id);
}

/// Implementation of [VetRemoteDataSource] using HTTP requests.
///
/// Communicates with the REST API at [baseUrl] to manage
/// veterinarian records. Uses [http.Client] for making requests.
class VetRemoteDataSourceImpl implements VetRemoteDataSource {
  /// Creates a [VetRemoteDataSourceImpl] with the given [baseUrl].
  ///
  /// An optional [client] can be provided for testing; otherwise,
  /// a default [http.Client] is used.
  VetRemoteDataSourceImpl({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// The base URL of the remote API.
  final String baseUrl;

  /// The HTTP client used for making requests.
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

  /// Validates the HTTP [response] and throws an [Exception] if the
  /// status code indicates an error (>= 400).
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
