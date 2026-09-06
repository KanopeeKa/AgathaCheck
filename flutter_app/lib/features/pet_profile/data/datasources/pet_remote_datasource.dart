import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/pet_model.dart';
import '../utils/pet_photo_bytes.dart';

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
  Future<PetModel> uploadPetPhoto(
    String petId,
    Uint8List bytes,
    String filename,
    String token,
  );
  Future<void> deletePet(String id, String token);
  Future<void> deletePetData(String id, String token);
  Future<int> notifyPassedAway(String petId, String petName, String token);
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

  PetRemoteException _errorFromResponse(
    http.Response response,
    String fallback,
  ) {
    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final message = data['error'] as String?;
      return PetRemoteException(
        message ?? fallback,
        statusCode: response.statusCode,
      );
    } catch (_) {
      return PetRemoteException(fallback, statusCode: response.statusCode);
    }
  }

  Map<String, dynamic> _petPayload(PetModel pet) {
    final payload = pet.toJson(includeWeightEntryDate: true);
    if (isPendingPetPhotoUpload(pet.photoPath)) {
      payload.remove('photoPath');
    }
    return payload;
  }

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
      body: json.encode(_petPayload(pet)),
    );
    if (response.statusCode >= 400) {
      throw _errorFromResponse(response, 'Failed to save pet');
    }
    return PetModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<PetModel> updatePet(PetModel pet, String token) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/pets/${pet.id}'),
      headers: _headers(token),
      body: json.encode(_petPayload(pet)),
    );
    if (response.statusCode >= 400) {
      throw _errorFromResponse(response, 'Failed to update pet');
    }
    return PetModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<PetModel> uploadPetPhoto(
    String petId,
    Uint8List bytes,
    String filename,
    String token,
  ) async {
    final uri = Uri.parse('$baseUrl/api/pets/$petId/photo');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes('photo', bytes, filename: filename),
      );

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode >= 400) {
      throw _errorFromResponse(response, 'Photo upload failed');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    final petJson = data['pet'] as Map<String, dynamic>?;
    if (petJson != null) {
      return PetModel.fromJson(petJson);
    }
    return PetModel.fromJson({
      'id': petId,
      'name': '',
      'species': '',
      'photoPath': data['photoPath'],
    });
  }

  @override
  Future<void> deletePet(String id, String token) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/pets/$id'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      throw PetRemoteException(
        'Failed to delete pet',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<void> deletePetData(String id, String token) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/pets/$id/data'),
      headers: _headers(token),
    );
    if (response.statusCode >= 400) {
      throw PetRemoteException(
        'Failed to delete pet data',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<int> notifyPassedAway(
    String petId,
    String petName,
    String token,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/pets/$petId/passed-away'),
      headers: _headers(token),
      body: json.encode({'pet_name': petName}),
    );
    if (response.statusCode >= 400) {
      throw PetRemoteException(
        'Failed to notify passed away',
        statusCode: response.statusCode,
      );
    }
    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return (data['notified_count'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
