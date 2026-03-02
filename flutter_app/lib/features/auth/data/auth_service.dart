import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class AuthUser {
  final String id;
  final String email;
  final String name;
  final String firstName;
  final String lastName;
  final String category;
  final String bio;
  final String photoUrl;
  final String createdAt;
  final String updatedAt;

  AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.category,
    required this.bio,
    required this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'pet_guardian',
      bio: json['bio']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  String get displayName {
    final full = '$firstName $lastName'.trim();
    if (full.isNotEmpty) return full;
    if (name.isNotEmpty) return name;
    return email;
  }

  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    final dn = displayName;
    if (dn.length >= 2) return dn.substring(0, 2).toUpperCase();
    if (dn.isNotEmpty) return dn[0].toUpperCase();
    return '';
  }
}

class AuthResult {
  final AuthUser user;
  final String accessToken;
  final String refreshToken;

  AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}

class AuthService {
  final String baseUrl;
  final http.Client _client;

  AuthService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? (kIsWeb ? '' : 'http://localhost:5000'),
        _client = client ?? http.Client();

  Future<AuthResult> signup({
    required String email,
    required String password,
    String name = '',
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password, 'name': name}),
    );
    if (response.statusCode >= 400) {
      final body = json.decode(response.body);
      throw Exception(body['error'] ?? 'Signup failed');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return AuthResult(
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: (data['access_token'] ?? data['accessToken']) as String,
      refreshToken: (data['refresh_token'] ?? data['refreshToken']) as String,
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    if (response.statusCode >= 400) {
      final body = json.decode(response.body);
      throw Exception(body['error'] ?? 'Login failed');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return AuthResult(
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: (data['access_token'] ?? data['accessToken']) as String,
      refreshToken: (data['refresh_token'] ?? data['refreshToken']) as String,
    );
  }

  Future<String> refreshToken(String refreshToken) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refresh_token': refreshToken}),
    );
    if (response.statusCode >= 400) {
      throw Exception('Session expired. Please log in again.');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return (data['access_token'] ?? data['accessToken']) as String;
  }

  Future<void> logout(String refreshToken) async {
    await _client.post(
      Uri.parse('$baseUrl/api/auth/logout'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refresh_token': refreshToken}),
    );
  }

  Future<AuthUser> getMe(String accessToken) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode >= 400) {
      throw Exception('Not authenticated');
    }
    return AuthUser.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  Future<AuthUser> updateMe(
    String accessToken, {
    String? name,
    String? firstName,
    String? lastName,
    String? category,
    String? bio,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (category != null) body['category'] = category;
    if (bio != null) body['bio'] = bio;

    final response = await _client.put(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode(body),
    );
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Update failed');
    }
    return AuthUser.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  Future<AuthUser> uploadPhoto(
      String accessToken, Uint8List bytes, String filename) async {
    final uri = Uri.parse('$baseUrl/api/auth/me/photo');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..files.add(http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: filename,
      ));

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Photo upload failed');
    }
    return AuthUser.fromJson(
        json.decode(response.body) as Map<String, dynamic>);
  }

  Future<String> changePassword(
    String accessToken, {
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Password change failed');
    }
    return data['message'] as String;
  }
}
