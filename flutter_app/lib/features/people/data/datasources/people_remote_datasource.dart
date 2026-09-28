import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/people_contact_model.dart';

abstract class PeopleRemoteDataSource {
  Future<List<PeopleContactModel>> listContacts({bool includeInactive = false});
  Future<PeopleContactModel> createContact(PeopleContactModel draft);
  Future<PeopleContactModel> updateContact(
    String id,
    Map<String, dynamic> patch,
  );
  Future<void> deleteContact(String id);
}

class PeopleRemoteDataSourceImpl implements PeopleRemoteDataSource {
  PeopleRemoteDataSourceImpl({
    required this.baseUrl,
    this.token,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String? token;
  final http.Client _client;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  @override
  Future<List<PeopleContactModel>> listContacts({
    bool includeInactive = false,
  }) async {
    final query = includeInactive ? '?include_inactive=true' : '';
    final response = await _client.get(
      Uri.parse('$baseUrl/api/people/contacts$query'),
      headers: _headers,
    );
    _checkResponse(response);
    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map((e) => PeopleContactModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PeopleContactModel> updateContact(
    String id,
    Map<String, dynamic> patch,
  ) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/people/contacts/$id'),
      headers: _headers,
      body: json.encode(patch),
    );
    _checkResponse(response);
    return PeopleContactModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteContact(String id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/people/contacts/$id'),
      headers: _headers,
    );
    _checkResponse(response);
  }

  @override
  Future<PeopleContactModel> createContact(PeopleContactModel draft) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/people/contacts'),
      headers: _headers,
      body: json.encode(draft.toCreateJson()),
    );
    _checkResponse(response);
    return PeopleContactModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw HttpException('People API ${response.statusCode}: ${response.body}');
  }
}

class HttpException implements Exception {
  HttpException(this.message);
  final String message;
  @override
  String toString() => message;
}
