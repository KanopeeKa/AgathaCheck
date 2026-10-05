import 'package:go_router/go_router.dart';

const peopleHubWideBreakpoint = 840.0;

bool peopleHubIsIndexRoute(GoRouterState state) {
  final path = state.uri.path;
  return path == '/pc/people' || path == '/pc/people/';
}

String? peoplePersonIdFromState(GoRouterState state) {
  final id = state.pathParameters['personId'];
  if (id != null && id.isNotEmpty && id != 'new' && id != 'households') {
    return id;
  }
  final segments = state.uri.pathSegments;
  final idx = segments.indexOf('people');
  if (idx >= 0 && segments.length > idx + 1) {
    final next = segments[idx + 1];
    if (next != 'new' && next != 'households') return next;
  }
  return null;
}

String peopleHubShellLocation(GoRouterState state) {
  final personId = peoplePersonIdFromState(state);
  if (personId != null) return '/pc/people/$personId';
  return '/pc/people';
}

String peopleHubNavigatePath({
  required String? personId,
  required Map<String, String> queryParameters,
}) {
  final query = _encodeQuery(queryParameters);
  if (personId == null || personId.isEmpty) {
    return query.isEmpty ? '/pc/people' : '/pc/people?$query';
  }
  return query.isEmpty ? '/pc/people/$personId' : '/pc/people/$personId?$query';
}

String _encodeQuery(Map<String, String> params) {
  if (params.isEmpty) return '';
  return params.entries
      .map(
        (e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
      )
      .join('&');
}
