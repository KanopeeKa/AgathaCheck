import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'auth_client_stub.dart' if (dart.library.html) 'auth_client_web.dart';
import 'token_store.dart';

class AuthUser {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? category;
  final String? bio;
  final String? photoUrl;
  final String? pinnedOrganizationId;
  final String? createdAt;
  final String? updatedAt;

  AuthUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.category,
    this.bio,
    this.photoUrl,
    this.pinnedOrganizationId,
    this.createdAt,
    this.updatedAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      category: json['category']?.toString(),
      bio: json['bio']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      pinnedOrganizationId: json['pinned_organization_id']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  String get displayName {
    final full = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (full.isNotEmpty) return full;
    return email;
  }

  String get initials {
    if ((firstName?.isNotEmpty ?? false) && (lastName?.isNotEmpty ?? false)) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
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
      _client = client ?? createAuthHttpClient();

  AuthResult _parseAuthResult(Map<String, dynamic> data) {
    final refreshFromBody =
        (data['refresh_token'] ?? data['refreshToken']) as String?;
    final refreshToken = kIsWeb && refreshFromBody == null
        ? kHttpOnlyRefreshSentinel
        : refreshFromBody!;
    return AuthResult(
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: (data['access_token'] ?? data['accessToken']) as String,
      refreshToken: refreshToken,
    );
  }

  Future<AuthResult> signup({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      }),
    );
    if (response.statusCode >= 400) {
      final body = json.decode(response.body);
      throw Exception(body['error'] ?? 'Signup failed');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return _parseAuthResult(data);
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
    return _parseAuthResult(data);
  }

  Future<String> refreshToken(String refreshToken) async {
    final useCookieOnly = kIsWeb && refreshToken == kHttpOnlyRefreshSentinel;
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: useCookieOnly
          ? json.encode({})
          : json.encode({'refresh_token': refreshToken}),
    );
    if (response.statusCode >= 400) {
      throw Exception('Session expired. Please log in again.');
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return (data['access_token'] ?? data['accessToken']) as String;
  }

  Future<void> logout(String refreshToken, {String? accessToken}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    final useCookieOnly = kIsWeb && refreshToken == kHttpOnlyRefreshSentinel;
    await _client.post(
      Uri.parse('$baseUrl/api/auth/logout'),
      headers: headers,
      body: useCookieOnly
          ? json.encode({})
          : json.encode({'refresh_token': refreshToken}),
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
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AuthUser> updateMe(
    String accessToken, {
    String? firstName,
    String? lastName,
    String? category,
    String? bio,
    String? locale,
    String? pinnedOrganizationId,
    bool updatePinnedOrganizationId = false,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (category != null) body['category'] = category;
    if (bio != null) body['bio'] = bio;
    if (locale != null) body['locale'] = locale;
    if (updatePinnedOrganizationId) {
      body['pinned_organization_id'] = pinnedOrganizationId;
    }

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
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AuthUser> uploadPhoto(
    String accessToken,
    Uint8List bytes,
    String filename,
  ) async {
    final uri = Uri.parse('$baseUrl/api/auth/me/photo');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..files.add(
        http.MultipartFile.fromBytes('photo', bytes, filename: filename),
      );

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode >= 400) {
      final data = json.decode(response.body);
      throw Exception(data['error'] ?? 'Photo upload failed');
    }
    return AuthUser.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
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

  Future<String> forgotPassword({required String email}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Request failed');
    }
    return data['message'] as String;
  }

  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'code': code,
        'new_password': newPassword,
      }),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Reset failed');
    }
    return data['message'] as String;
  }

  Future<String> deleteAccount(
    String accessToken, {
    required String password,
  }) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({'password': password}),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Account deletion failed');
    }
    return data['message'] as String;
  }

  Future<Map<String, dynamic>> exportData(String accessToken) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/auth/me/export'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode >= 400) {
      throw Exception('Data export failed');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }
}
