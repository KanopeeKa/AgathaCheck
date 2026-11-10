import 'package:go_router/go_router.dart';

import '../../features/experience/presentation/screens/pet_care/care_list/global_events_pet_query.dart';
import 'shell_return_navigation.dart';

/// Redirect legacy recurring-care URLs to the unified All care destination.
String? legacyPetAllCareRedirectForPath(String path) {
  final match = RegExp(r'^/pet/([^/]+)/care-rhythms$').firstMatch(path);
  if (match == null) return null;
  final petId = match.group(1)!;
  return globalAllCareLocation(petIds: {petId});
}

/// Maps `/pet/:petId/events` (list only) to global All care with that pet chip.
String redirectPetScopedAllCareList(GoRouterState state) {
  return redirectPetScopedAllCareTarget(
    petId: state.pathParameters['petId']!,
    uri: state.uri,
  );
}

/// Testable redirect target for pet-scoped All care list URLs.
String redirectPetScopedAllCareTarget({
  required String petId,
  required Uri uri,
}) {
  final params = Map<String, String>.from(uri.queryParameters);
  params.remove(GlobalEventsPetQuery.queryParam);
  final returnTo = parseShellReturnTo(uri.queryParameters['returnTo']);
  params.remove('returnTo');
  return globalAllCareLocation(
    petIds: {petId},
    returnTo: returnTo,
    baseQuery: params,
  );
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
