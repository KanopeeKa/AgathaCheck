import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../hub/people_hub_layout.dart';
import '../add/add_person_flow.dart';
import '../add/add_person_route_args.dart';
import '../detail/person_detail_page.dart';
import '../edit/person_edit_page.dart';

RouteBase buildPeopleHubShellRoute() {
  return ShellRoute(
    builder: (context, state, child) => PeopleHubLayout(child: child),
    routes: [
      GoRoute(
        path: '/pc/people',
        name: 'petCarePeople',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const SizedBox.shrink(),
        ),
        routes: [
          GoRoute(
            path: 'new',
            name: 'petCarePeopleNew',
            builder: (context, state) {
              final extra = state.extra;
              final args = extra is AddPersonRouteArgs ? extra : null;
              return AddPersonFlow(args: args);
            },
          ),
          GoRoute(
            path: 'households',
            name: 'petCarePeopleHouseholds',
            redirect: (context, state) => '/pc/pets/households',
          ),
          GoRoute(
            path: ':personId',
            name: 'petCarePeopleDetail',
            builder: (context, state) {
              final personId = state.pathParameters['personId']!;
              return PersonDetailPage(
                personId: personId,
                embedded: peopleDetailShouldEmbed(context),
              );
            },
            routes: [
              GoRoute(
                path: 'edit',
                name: 'petCarePeopleEdit',
                builder: (context, state) =>
                    PersonEditPage(personId: state.pathParameters['personId']!),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
