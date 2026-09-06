/// Resolves health file API paths for authenticated fetch.
///
/// Health attachments use `/api/health-files/:id` and require a Bearer token.
/// On web with a relative API prefix (e.g. `/backend`), prefix with the API base.
String resolveHealthFileUrl(String path, {required String apiBaseUrl}) {
  if (path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  if (path.startsWith('/api/health-files/')) {
    if (apiBaseUrl.startsWith('http://') || apiBaseUrl.startsWith('https://')) {
      return '$apiBaseUrl$path';
    }
    if (apiBaseUrl.isNotEmpty && apiBaseUrl.startsWith('/')) {
      return '$apiBaseUrl$path';
    }
    return path;
  }
  if (path.startsWith('/uploads/health_')) {
    // Legacy public URLs — still routed for migration period via health-files API
    // after DB backfill; callers should prefer /api/health-files paths from API.
    if (apiBaseUrl.startsWith('http://') || apiBaseUrl.startsWith('https://')) {
      return '$apiBaseUrl$path';
    }
    if (apiBaseUrl.isNotEmpty && apiBaseUrl.startsWith('/')) {
      return '$apiBaseUrl/api$path';
    }
  }
  return '$apiBaseUrl$path';
}

bool isPrivateHealthFileUrl(String path) {
  return path.startsWith('/api/health-files/');
}
