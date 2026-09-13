/// Redirect legacy recurring-care URLs to the unified All care destination.
String? legacyPetAllCareRedirectForPath(String path) {
  final match = RegExp(r'^/pet/([^/]+)/care-rhythms$').firstMatch(path);
  if (match == null) return null;
  return '/pet/${match.group(1)}/events';
}
