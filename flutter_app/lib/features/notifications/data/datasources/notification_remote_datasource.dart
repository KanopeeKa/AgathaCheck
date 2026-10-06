import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications(String token);
  Future<int> getUnreadCount(String token);
  Future<void> markAsRead(String token, String id);
  Future<void> markAllAsRead(String token, {String scope = 'activity'});
  Future<NotificationPreferencesModel> getPreferences(String token);
  Future<NotificationPreferencesModel> updatePreferences(
    String token,
    NotificationPreferencesModel preferences,
  );
  Future<void> dismissV2InboxExplainer(String token);
  Future<void> dismissDeviceSecurityIntro(String token);
  Future<void> checkDueEntries(
    String token, {
    Map<String, String> petNames = const {},
  });
  Future<void> markSuggestionsSeen(String token, {String? petId});
  Future<void> submitSuggestionFeedback(
    String token,
    String notificationId,
    String action,
  );
  Future<void> submitAccountSecurityFeedback(
    String token,
    String notificationId,
    String action,
  );
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  @override
  Future<List<NotificationModel>> getNotifications(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/notifications'),
      headers: _headers(token),
    );
    _checkResponse(response);
    final list = json.decode(response.body) as List<dynamic>;
    return list
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> getUnreadCount(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/notifications/unread-count'),
      headers: _headers(token),
    );
    _checkResponse(response);
    final data = json.decode(response.body) as Map<String, dynamic>;
    return (data['unread_count'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> markAsRead(String token, String id) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/notifications/$id/read'),
      headers: _headers(token),
    );
    _checkResponse(response);
  }

  @override
  Future<void> markAllAsRead(String token, {String scope = 'activity'}) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/notifications/read-all'),
      headers: _headers(token),
      body: json.encode({'scope': scope}),
    );
    _checkResponse(response);
  }

  @override
  Future<NotificationPreferencesModel> getPreferences(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/notifications/preferences'),
      headers: _headers(token),
    );
    _checkResponse(response);
    return NotificationPreferencesModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> dismissV2InboxExplainer(String token) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/notifications/preferences'),
      headers: _headers(token),
      body: json.encode({
        'v2_explainer_dismissed_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    _checkResponse(response);
  }

  @override
  Future<void> dismissDeviceSecurityIntro(String token) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/notifications/preferences'),
      headers: _headers(token),
      body: json.encode({
        'device_security_intro_dismissed_at': DateTime.now()
            .toUtc()
            .toIso8601String(),
      }),
    );
    _checkResponse(response);
  }

  @override
  Future<NotificationPreferencesModel> updatePreferences(
    String token,
    NotificationPreferencesModel preferences,
  ) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/api/notifications/preferences'),
      headers: _headers(token),
      body: json.encode(preferences.toJson()),
    );
    _checkResponse(response);
    return NotificationPreferencesModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> checkDueEntries(
    String token, {
    Map<String, String> petNames = const {},
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/notifications/check-due'),
      headers: _headers(token),
      body: json.encode({'pet_names': petNames}),
    );
    _checkResponse(response);
  }

  @override
  Future<void> markSuggestionsSeen(String token, {String? petId}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/notifications/suggestions/seen'),
      headers: _headers(token),
      body: json.encode({
        if (petId != null && petId.isNotEmpty) 'pet_id': petId,
      }),
    );
    _checkResponse(response);
  }

  @override
  Future<void> submitSuggestionFeedback(
    String token,
    String notificationId,
    String action,
  ) async {
    final response = await _client.post(
      Uri.parse(
        '$baseUrl/api/notifications/$notificationId/suggestion-feedback',
      ),
      headers: _headers(token),
      body: json.encode({'action': action}),
    );
    _checkResponse(response);
  }

  @override
  Future<void> submitAccountSecurityFeedback(
    String token,
    String notificationId,
    String action,
  ) async {
    final response = await _client.post(
      Uri.parse(
        '$baseUrl/api/notifications/$notificationId/account-security-feedback',
      ),
      headers: _headers(token),
      body: json.encode({'action': action}),
    );
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
