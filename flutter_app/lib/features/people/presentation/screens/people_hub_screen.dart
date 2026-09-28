import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'people_detail_screen.dart';
import 'people_list_screen.dart';

/// People hub: list plus optional detail pane on wide layouts.
class PeopleHubScreen extends StatelessWidget {
  const PeopleHubScreen({super.key, this.selectedPersonId});

  final String? selectedPersonId;

  static const _wideBreakpoint = 840.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final personId = selectedPersonId;
    if (width >= _wideBreakpoint && personId != null && personId.isNotEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(flex: 4, child: PeopleListScreen()),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 6,
            child: PeopleDetailScreen(personId: personId, embedded: true),
          ),
        ],
      );
    }
    if (personId != null && personId.isNotEmpty) {
      return PeopleDetailScreen(personId: personId);
    }
    return const PeopleListScreen();
  }
}

String? peoplePersonIdFromState(GoRouterState state) {
  final id = state.pathParameters['personId'];
  if (id != null && id.isNotEmpty) return id;
  final segments = state.uri.pathSegments;
  final idx = segments.indexOf('people');
  if (idx >= 0 && segments.length > idx + 1) {
    final next = segments[idx + 1];
    if (next != 'new') return next;
  }
  return null;
}
