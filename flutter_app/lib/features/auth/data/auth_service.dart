// Auth service — handles REST API calls for authentication.
// Endpoints: POST /api/auth/signup, /login, /refresh, /logout
//            GET /api/auth/me, PUT /api/auth/me, POST /api/auth/change-password

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class AuthUser {
  final String id;
  final String email;
  final String name;
  final String createdAt;
  final String updatedAt;

  AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
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
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
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
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }

  Future<String> refreshToken(String refreshToken) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refreshToken': refreshToken}),
    );
    if (response.statusCode >= 400) {
      throw Exception('Session expired. Please log in again.');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['accessToken'] as String;
  }

  Future<void> logout(String refreshToken) async {
    await _client.post(
      Uri.parse('$baseUrl/api/auth/logout'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refreshToken': refreshToken}),
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

  Future<AuthUser> updateMe(String accessToken, {required String name}) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({'name': name}),
    );
    if (response.statusCode >= 400) {
      final body = json.decode(response.body);
      throw Exception(body['error'] ?? 'Update failed');
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
