import 'package:go_router/go_router.dart';

/// Redirect legacy recurring-care URLs to the unified All care destination.
String? legacyPetAllCareRedirectForPath(String path) {
  final match = RegExp(r'^/pet/([^/]+)/care-rhythms$').firstMatch(path);
  if (match == null) return null;
  return '/pet/${match.group(1)}/events';
}

/// Maps deprecated health/other add paths to unified care add routes.
String? legacyCareAddRedirectForPath(String path) {
  final petHealthMatch = RegExp(r'^/pet/([^/]+)/health/add$').firstMatch(path);
  if (petHealthMatch != null) {
    return '/pet/${petHealthMatch.group(1)}/care/add';
  }

  final petOtherMatch = RegExp(r'^/pet/([^/]+)/other/add$').firstMatch(path);
  if (petOtherMatch != null) {
    return '/pet/${petOtherMatch.group(1)}/care/add';
  }

  if (path == '/health/add') {
    return '/care/add';
  }

  return null;
}

/// Redirect helper preserving query parameters (e.g. `?planning=unplanned`).
String? redirectLegacyCareAddPath(GoRouterState state) {
  final target = legacyCareAddRedirectForPath(state.uri.path);
  if (target == null) return null;
  final query = state.uri.query;
  return query.isEmpty ? target : '$target?$query';
}
