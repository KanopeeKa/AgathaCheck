import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/roster.dart';
import '../detail/person_detail_target.dart';
import 'people_hub_route.dart';
import 'roster_hub_query.dart';

/// Compact-width chrome for routes under the People hub shell.
class PeopleHubShellChrome {
  const PeopleHubShellChrome({
    required this.screenTitle,
    this.contextualActions = const [],
    this.backPath,
    this.forceBackPath = false,
  });

  final String screenTitle;
  final List<Widget> contextualActions;
  final String? backPath;
  final bool forceBackPath;
}

PeopleHubShellChrome resolvePeopleHubCompactChrome({
  required BuildContext context,
  required GoRouterState state,
  required AppLocalizations l,
  required Roster? roster,
}) {
  final path = state.uri.path;
  final hubQuery = RosterHubQuery.fromUri(state.uri);
  final listBackPath = peopleHubNavigatePath(
    personId: null,
    queryParameters: hubQuery.toQueryParameters(),
  );

  if (path.endsWith('/new')) {
    return PeopleHubShellChrome(
      screenTitle: l.peopleAddPerson,
      backPath: listBackPath,
      forceBackPath: true,
    );
  }

  if (path.contains('/households/')) {
    final householdId = state.pathParameters['householdId'];
    return PeopleHubShellChrome(
      screenTitle: l.householdsTitle,
      backPath: householdId == null
          ? listBackPath
          : '/pc/people/households',
      forceBackPath: true,
    );
  }

  if (path.endsWith('/households') || path.endsWith('/households/')) {
    return PeopleHubShellChrome(
      screenTitle: l.householdsTitle,
      backPath: listBackPath,
      forceBackPath: true,
    );
  }

  if (path.endsWith('/edit')) {
    final personId = state.pathParameters['personId'];
    return PeopleHubShellChrome(
      screenTitle: l.peopleEditPerson,
      backPath: personId == null ? listBackPath : '/pc/people/$personId',
      forceBackPath: true,
    );
  }

  final personId = peoplePersonIdFromState(state);
  if (personId != null) {
    final title = _personTitle(l, roster, personId);
    final target =
        roster == null ? null : resolvePersonDetailTarget(roster, personId);
    final editAction = target is PersonDetailContactTarget
      ? IconButton(
          key: const Key('people_hub_edit_person'),
          tooltip: l.peopleEditPerson,
          onPressed: () => context.push('/pc/people/$personId/edit'),
          icon: const Icon(Icons.edit_outlined),
        )
      : null;

    return PeopleHubShellChrome(
      screenTitle: title,
      contextualActions: editAction == null ? const [] : [editAction],
      backPath: listBackPath,
      forceBackPath: true,
    );
  }

  return PeopleHubShellChrome(
    screenTitle: l.peoplePageTitle,
  );
}

String _personTitle(AppLocalizations l, Roster? roster, String personId) {
  if (roster == null) return l.peoplePageTitle;
  final target = resolvePersonDetailTarget(roster, personId);
  return switch (target) {
    PersonDetailContactTarget() =>
      roster.summaryById(personId)?.name ?? l.peoplePageTitle,
    PersonDetailHouseholdMemberTarget(:final member) => member.displayName,
    PersonDetailPendingInviteTarget(:final invite) => invite.email,
    null => l.peoplePageTitle,
  };
}

bool peopleHubSkipsInnerAppBar(BuildContext context) {
  return MediaQuery.sizeOf(context).width < peopleHubWideBreakpoint;
}

bool peopleHubWidePaneMode(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= peopleHubWideBreakpoint;
}

/// Pane-local [Scaffold] on wide layouts; body only when the hub owns the shell bar.
Widget peopleHubPaneScaffold({
  required BuildContext context,
  required Widget title,
  required Widget body,
  VoidCallback? onBack,
  Widget? bottomNavigationBar,
}) {
  if (peopleHubSkipsInnerAppBar(context)) {
    if (bottomNavigationBar == null) return body;
    return Column(
      children: [
        Expanded(child: body),
        bottomNavigationBar,
      ],
    );
  }
  return Scaffold(
    appBar: AppBar(
      title: title,
      leading: onBack == null ? null : BackButton(onPressed: onBack),
    ),
    body: body,
    bottomNavigationBar: bottomNavigationBar,
  );
}
