import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../hub/people_hub_layout.dart';
import '../screens/people_add_person_screen.dart';
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
              final rolesParam = state.uri.queryParameters['roles'];
              final roles = rolesParam == null
                  ? const <String>{}
                  : rolesParam
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toSet();
              final pop = state.uri.queryParameters['pop'] == '1';
              return PeopleAddPersonScreen(
                initialRoles: roles,
                popResultOnSave: pop,
              );
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
