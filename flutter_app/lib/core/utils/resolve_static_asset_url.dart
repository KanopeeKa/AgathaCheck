/// Resolves a relative asset path (photo_url, logo_url, etc.) to a loadable URL.
///
/// Static uploads under `/uploads/` are persisted on disk with restrictive
/// permissions. On web (relative [apiBaseUrl] such as `/backend`), Apache blocks
/// direct GETs to `/backend/uploads/*`, so images load via the API route
/// `/backend/api/uploads/...` which Passenger forwards to Node.
/// On mobile dev with an absolute [apiBaseUrl], express.static serves `/uploads/`.
String resolveStaticAssetUrl(String path, {required String apiBaseUrl}) {
  if (path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  if (path.startsWith('/uploads/')) {
    return _resolveUploadPath(path, apiBaseUrl);
  }
  return '$apiBaseUrl$path';
}

String _resolveUploadPath(String path, String apiBaseUrl) {
  if (apiBaseUrl.startsWith('http://') || apiBaseUrl.startsWith('https://')) {
    return '$apiBaseUrl$path';
  }
  // Relative API prefix (e.g. '/backend' on web) → API upload route.
  if (apiBaseUrl.isNotEmpty && apiBaseUrl.startsWith('/')) {
    return '$apiBaseUrl/api$path';
  }
  return path;
}
