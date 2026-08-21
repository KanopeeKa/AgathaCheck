import 'dart:convert';

import '../../../data/datasources/organization_remote/organization_remote_context.dart';

class FosterQuestionnaireRemote {
  FosterQuestionnaireRemote(this._ctx);

  final OrganizationRemoteContext _ctx;

  Future<Map<String, dynamic>> loadTemplate(String orgId, String token) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/foster-questionnaire/template'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to load foster questionnaire');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitQuestionnaire(
    String orgId, {
    required List<Map<String, dynamic>> answers,
    required String generalNote,
    required bool candidateAcknowledged,
    required String token,
  }) async {
    final response = await _ctx.client.post(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/foster-questionnaire/submit'),
      headers: _ctx.headers(token),
      body: json.encode({
        'answers': answers,
        'general_note': generalNote,
        'candidate_acknowledged': candidateAcknowledged,
      }),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Failed to submit foster questionnaire');
    }
    return data;
  }

  Future<Map<String, dynamic>> getSubmissionReview(
    String orgId,
    String fosterParentId,
    String token,
  ) async {
    final response = await _ctx.client.get(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/foster-questionnaire/submissions/$fosterParentId',
      ),
      headers: _ctx.headers(token),
    );
    final data = json.decode(response.body);
    if (response.statusCode >= 400) {
      final message = data is Map ? data['error']?.toString() : null;
      throw Exception(message ?? 'Failed to load foster questionnaire submission');
    }
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> recordDecision(
    String orgId,
    String submissionId, {
    required String decision,
    required String structuredReason,
    String staffNotes = '',
    required String token,
  }) async {
    final response = await _ctx.client.post(
      Uri.parse(
        '${_ctx.baseUrl}/api/organizations/$orgId/foster-questionnaire/submissions/$submissionId/decision',
      ),
      headers: _ctx.headers(token),
      body: json.encode({
        'decision': decision,
        'structured_reason': structuredReason,
        if (staffNotes.isNotEmpty) 'staff_notes': staffNotes,
      }),
    );
    final data = json.decode(response.body);
    if (response.statusCode >= 400) {
      final message = data is Map ? data['error']?.toString() : null;
      throw Exception(message ?? 'Failed to record foster questionnaire decision');
    }
    final decisionJson = (data as Map)['decision'];
    if (decisionJson is! Map) {
      throw Exception('Invalid foster questionnaire decision response');
    }
    return Map<String, dynamic>.from(decisionJson);
  }
}
