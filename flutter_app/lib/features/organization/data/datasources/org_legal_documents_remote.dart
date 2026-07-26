import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/org_legal_document.dart';

class OrgLegalDocumentsRemote {
  OrgLegalDocumentsRemote({required this.baseUrl, required this.client});

  final String baseUrl;
  final http.Client client;

  Future<Map<String, List<OrgLegalDocument>>> fetchPublicDocuments({
    required String orgId,
    required String token,
  }) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/organizations/$orgId/legal-documents'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load legal documents (${response.statusCode})',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return {};
    return parseGroupedLegalDocuments(decoded);
  }

  Future<({String filename, String content})> downloadDocument({
    required String orgId,
    required String templateId,
    required String token,
  }) async {
    final response = await client.get(
      Uri.parse(
        '$baseUrl/api/organizations/$orgId/legal-documents/$templateId/download',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to download document (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      filename: decoded['filename']?.toString() ?? 'document.md',
      content: decoded['content']?.toString() ?? '',
    );
  }
}
