import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/entities/household.dart';
import '../domain/repositories/people_repository.dart';
import 'dto/people_dtos.dart';

class HouseholdsApi {
  HouseholdsApi({
    required this.baseUrl,
    required this.client,
    this.token,
  });

  final String baseUrl;
  final http.Client client;
  final String? token;

  Future<List<Household>> listHouseholds() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/households'),
      headers: {
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode >= 400) {
      throw Exception('Households API ${response.statusCode}');
    }
    final decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic>) {
      final list = decoded['households'] as List? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(HouseholdDto.fromJson)
          .toList();
    }
    return const [];
  }
}

class HouseholdsRepositoryImpl implements HouseholdsRepository {
  HouseholdsRepositoryImpl(this._api);

  final HouseholdsApi _api;

  @override
  Future<List<Household>> listHouseholds() => _api.listHouseholds();
}
