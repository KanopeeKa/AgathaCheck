import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/auth/auth.dart';

/// Loads `care_closed_reason` for detail subtitle (phase-4 scope: detail layer only).
final careItemClosedReasonProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, entryId) async {
      final baseUrl = ref.watch(apiBaseUrlProvider);
      final client = ref.watch(authHttpClientProvider);
      final uri = Uri.parse('$baseUrl/api/health-entries/$entryId');
      final response = await client.get(uri);
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 'closed') return null;
      return json['care_closed_reason'] as String?;
    });
