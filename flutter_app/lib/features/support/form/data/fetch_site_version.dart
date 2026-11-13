import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'site_version_info.dart';

/// Loads [SiteVersionInfo] from the site-root `version.json` (not under `/backend`).
Future<SiteVersionInfo> fetchSiteVersion({http.Client? client}) async {
  if (!kIsWeb) {
    return SiteVersionInfo.empty();
  }
  final httpClient = client ?? http.Client();
  final uri = Uri.parse(
    '/version.json',
  ).replace(queryParameters: {'_': DateTime.now().millisecondsSinceEpoch.toString()});
  try {
    final response = await httpClient.get(uri);
    if (response.statusCode != 200) {
      return SiteVersionInfo.empty();
    }
    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return SiteVersionInfo.empty();
    }
    return SiteVersionInfo(
      version: decoded['version']?.toString() ?? '',
      build: decoded['build']?.toString() ?? '',
    );
  } catch (_) {
    return SiteVersionInfo.empty();
  } finally {
    if (client == null) {
      httpClient.close();
    }
  }
}
