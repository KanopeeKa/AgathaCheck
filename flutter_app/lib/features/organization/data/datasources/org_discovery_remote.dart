import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/discoverable_organization_model.dart';

class OrgDiscoveryRemote {
  OrgDiscoveryRemote({required this.baseUrl, required this.client});

  final String baseUrl;
  final http.Client client;

  Future<DiscoverOrganizationsPageModel> fetchDiscoverableOrganizations({
    int page = 1,
    int pageSize = 20,
    String? query,
  }) async {
    final queryParams = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
    };
    final trimmedQuery = query?.trim() ?? '';
    if (trimmedQuery.isNotEmpty) {
      queryParams['q'] = trimmedQuery;
    }
    final uri = Uri.parse(
      '$baseUrl/api/organizations/discover',
    ).replace(queryParameters: queryParams);
    final response = await client.get(uri);
    if (response.statusCode >= 400) {
      throw OrgDiscoveryException(
        'Failed to load discoverable organisations (${response.statusCode})',
      );
    }
    return DiscoverOrganizationsPageModel.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }
}

class OrgDiscoveryException implements Exception {
  OrgDiscoveryException(this.message);

  final String message;

  @override
  String toString() => message;
}
