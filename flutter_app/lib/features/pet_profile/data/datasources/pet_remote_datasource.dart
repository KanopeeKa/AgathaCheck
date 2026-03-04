import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/pet_model.dart';

class PetRemoteException implements Exception {
  PetRemoteException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'PetRemoteException($statusCode): $message';
}

abstract class PetRemoteDataSource {
  Future<List<PetModel>> getAllPets(String token);
  Future<List<PetModel>> getAllPetsIncludingOrg(String token);
  Future<PetModel> createPet(PetModel pet, String token);
  Future<PetModel> updatePet(PetModel pet, String token);
  Future<void> deletePet(String id, String token);
}

class PetRemoteDataSourceImpl implements PetRemoteDataSource {
  PetRemoteDataSourceImpl({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  @override
  Future<List<PetModel>> getAllPets(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/pets'),
      headers: _headers(token),
    );
    if (response.statusCode == 401) {
      throw PetRemoteException('Unauthorized', statusCode: 401);
    }
    if (response.statusCode >= 400) {
      throw PetRemoteException('Server error', statusCode: response.statusCode);
    }
    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map((e) => PetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PetModel>> getAllPetsIncludingOrg(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/pets/all'),
      headers: _headers(token),
    );
    if (response.statusCode == 401) {
      throw PetRemoteException('Unauthorized', statusCode: 401);
    }
    if (response.statusCode >= 400) {
      throw PetRemoteException('Server error', statusCode: response.statusCode);
    }
    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map((e) => PetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PetModel> createPet(PetModel pet, String token) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/pets'),
      headers: _headers(token),
      body: json.encode(pet.toJson()),
    );
    if (response.statusCode >= 400) {
      throw PetRemoteException('Failed to save pet', statusCode: response.statusCode);
    }
    return PetModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<PetModel> updatePet(PetModel pet, String token) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/pets/${pet.id}'),
      headers: _headers(token),
      body: json.encode(pet.toJson()),
    );
    if (response.statusCode >= 400) {
      throw PetRemoteException('Failed to update pet', statusCode: response.statusCode);
    }
    return PetModel.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<void> deletePet(String id, String token) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/pets/$id'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      debugPrint('PetRemoteDataSource: deletePet failed with ${response.statusCode}');
    }
  }
}
