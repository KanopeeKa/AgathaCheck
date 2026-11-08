import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/experience/experience.dart';

/// Production route builder for Care date (`occurrenceDetail`).
///
/// Keys the screen by [occurrenceId] so go_router replace hops reload data.
Widget buildOccurrenceDetailScreen(BuildContext context, GoRouterState state) {
  return OccurrenceScreen(
    key: ValueKey('occurrence-${state.pathParameters['occurrenceId']}'),
    petId: state.pathParameters['petId']!,
    entryId: state.pathParameters['entryId']!,
    occurrenceId: state.pathParameters['occurrenceId']!,
    focus: state.uri.queryParameters['focus'],
  );
}
