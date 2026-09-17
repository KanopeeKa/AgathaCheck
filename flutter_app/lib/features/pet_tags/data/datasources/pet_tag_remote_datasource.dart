import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pet_tag_model.dart';

abstract class PetTagRemoteDataSource {
  Future<List<PetTagModel>> listTags(String token);
  Future<PetTagModel> createTag(String token, String name);
  Future<PetTagModel> renameTag(String token, String tagId, String name);
  Future<void> deleteTag(String token, String tagId);
  Future<void> assignTag(String token, String petId, String tagId);
  Future<void> unassignTag(String token, String petId, String tagId);
}

class PetTagRemoteDataSourceImpl implements PetTagRemoteDataSource {
  PetTagRemoteDataSourceImpl({required this.baseUrl, required this.client});

  final String baseUrl;
  final http.Client client;

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw PetTagApiException(response.statusCode, response.body);
  }

  @override
  Future<List<PetTagModel>> listTags(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/pet-tags'),
      headers: _headers(token),
    );
    _checkResponse(response);
    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map((item) => PetTagModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PetTagModel> createTag(String token, String name) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/pet-tags'),
      headers: _headers(token),
      body: json.encode({'name': name}),
    );
    _checkResponse(response);
    return PetTagModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<PetTagModel> renameTag(String token, String tagId, String name) async {
    final response = await client.patch(
      Uri.parse('$baseUrl/api/pet-tags/$tagId'),
      headers: _headers(token),
      body: json.encode({'name': name}),
    );
    _checkResponse(response);
    return PetTagModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteTag(String token, String tagId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/pet-tags/$tagId'),
      headers: _headers(token),
    );
    _checkResponse(response);
  }

  @override
  Future<void> assignTag(String token, String petId, String tagId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/pets/$petId/tags'),
      headers: _headers(token),
      body: json.encode({'tag_id': tagId}),
    );
    _checkResponse(response);
  }

  @override
  Future<void> unassignTag(String token, String petId, String tagId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/pets/$petId/tags/$tagId'),
      headers: _headers(token),
    );
    _checkResponse(response);
  }
}

class PetTagApiException implements Exception {
  PetTagApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'PetTagApiException($statusCode): $body';
}
