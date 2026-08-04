import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../models/organization_model.dart';
import 'organization_remote_context.dart';

class OrganizationCoreRemote {
  OrganizationCoreRemote(this._ctx);

  final OrganizationRemoteContext _ctx;

  Future<List<OrganizationModel>> getOrganizations(String token) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to get organizations');
    }
    final list = json.decode(response.body) as List;
    return list
        .map((e) => OrganizationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrganizationModel> getOrganization(String id, String token) async {
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$id'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to get organization');
    }
    return OrganizationModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<OrganizationModel> getPublicOrganization(
    String id, {
    String? token,
  }) async {
    final headers = token != null
        ? _ctx.headers(token)
        : const {'Content-Type': 'application/json'};
    final response = await _ctx.client.get(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$id/public'),
      headers: headers,
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to get public organization profile');
    }
    return OrganizationModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<OrganizationModel> createOrganization(
    Map<String, dynamic> orgJson,
    String token,
  ) async {
    final response = await _ctx.client.post(
      Uri.parse('${_ctx.baseUrl}/api/organizations'),
      headers: _ctx.headers(token),
      body: json.encode(orgJson),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to create organization');
    }
    return OrganizationModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<OrganizationModel> updateOrganization(
    String id,
    Map<String, dynamic> orgJson,
    String token,
  ) async {
    final response = await _ctx.client.put(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$id'),
      headers: _ctx.headers(token),
      body: json.encode(orgJson),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to update organization');
    }
    return OrganizationModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteOrganization(String id, String token) async {
    final response = await _ctx.client.delete(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$id'),
      headers: _ctx.headers(token),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to delete organization');
    }
  }

  Future<OrganizationModel> uploadPhoto(
    String id,
    Uint8List bytes,
    String filename,
    String token,
  ) async {
    return _uploadOrgImage(
      '${_ctx.baseUrl}/api/organizations/$id/photo',
      bytes,
      filename,
      token,
    );
  }

  Future<OrganizationModel> uploadLogo(
    String id,
    Uint8List bytes,
    String filename,
    String token,
  ) async {
    return _uploadOrgImage(
      '${_ctx.baseUrl}/api/organizations/$id/logo',
      bytes,
      filename,
      token,
    );
  }

  Future<OrganizationModel> setPrimaryContact(
    String orgId,
    String recordId,
    String token,
  ) async {
    final response = await _ctx.client.put(
      Uri.parse('${_ctx.baseUrl}/api/organizations/$orgId/primary-contact'),
      headers: _ctx.headers(token),
      body: json.encode({'kind': 'member', 'record_id': recordId}),
    );
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Failed to set primary contact');
    }
    return OrganizationModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  Future<OrganizationModel> _uploadOrgImage(
    String url,
    Uint8List bytes,
    String filename,
    String token,
  ) async {
    final uri = Uri.parse(url);
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: filename,
          contentType: contentTypeForOrgImageFilename(filename),
        ),
      );
    final streamedResponse = await _ctx.client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode >= 400) {
      _ctx.throwApiError(response, 'Image upload failed');
    }
    return OrganizationModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }
}

/// Maps org image filename extensions to multipart MIME types for web uploads.
MediaType contentTypeForOrgImageFilename(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return MediaType('image', 'png');
  if (lower.endsWith('.webp')) return MediaType('image', 'webp');
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return MediaType('image', 'jpeg');
  }
  return MediaType('image', 'jpeg');
}
