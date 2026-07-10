/// Resolves a relative asset path (photo_url, logo_url, etc.) to a loadable URL.
///
/// Static uploads under `/uploads/` are served at site root, not under the API
/// prefix (`/backend` on web). Other relative paths are prefixed with
/// [apiBaseUrl].
String resolveStaticAssetUrl(String path, {required String apiBaseUrl}) {
  if (path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  if (path.startsWith('/uploads/')) {
    return '${_siteOriginFromApiBase(apiBaseUrl)}$path';
  }
  return '$apiBaseUrl$path';
}

String _siteOriginFromApiBase(String apiBaseUrl) {
  if (apiBaseUrl.startsWith('http://') || apiBaseUrl.startsWith('https://')) {
    return apiBaseUrl;
  }
  // Relative API prefix (e.g. '/backend' on web) → assets at site root.
  return '';
}
