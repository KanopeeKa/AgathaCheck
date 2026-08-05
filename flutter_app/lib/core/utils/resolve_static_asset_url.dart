/// Resolves a relative asset path (photo_url, logo_url, etc.) to a loadable URL.
///
/// Static uploads under `/uploads/` are served by the Node API. On web the API
/// prefix is `/backend`, so uploads load from `/backend/uploads/...` (Apache
/// serves the Flutter SPA at site root — `/uploads/*` would return index.html).
/// On mobile dev with an absolute [apiBaseUrl], uploads are under that origin.
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
  // Relative API prefix (e.g. '/backend' on web) → uploads under API mount.
  if (apiBaseUrl.isNotEmpty && apiBaseUrl.startsWith('/')) {
    return '$apiBaseUrl$path';
  }
  return path;
}
