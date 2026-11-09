import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import 'package:pet_profile_app/core/experience/app_experience.dart';
import 'package:pet_profile_app/core/router/experience_shell_scaffold.dart';
import '../../application/people_providers.dart';
import 'people_hub_placeholder.dart';
import 'people_hub_route.dart';
import 'people_hub_shell_chrome.dart';
import 'roster_list.dart';

/// Adaptive People hub: experience shell wraps list–detail (B4).
class PeopleHubLayout extends ConsumerWidget {
  const PeopleHubLayout({super.key, required this.child});

  final Widget child;

  static const listPaneWidth = 400.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = GoRouterState.of(context);
    final l = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= peopleHubWideBreakpoint;
    final personId = peoplePersonIdFromState(state);
    final isIndex = peopleHubIsIndexRoute(state);

    final listPane = SizedBox(
      width: wide ? listPaneWidth : null,
      child: RosterList(
        selectedPersonId: personId,
        showWideHeaderActions: wide,
      ),
    );

    Widget body;
    if (wide) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          listPane,
          const VerticalDivider(width: 1),
          Expanded(
            child: isIndex && personId == null
                ? const PeopleHubPlaceholder()
                : child,
          ),
        ],
      );
    } else if (isIndex && personId == null) {
      body = listPane;
    } else {
      body = child;
    }

    final showCompactFab = !wide && isIndex && personId == null;

    final rosterAsync = ref.watch(rosterProvider);
    final roster = rosterAsync.valueOrNull;

    String screenTitle = l.peoplePageTitle;
    List<Widget> contextualActions = const [];
    String? backPath;
    var forceBackPath = false;
    VoidCallback? onShellBack;

    if (!wide && !isIndex) {
      final chrome = resolvePeopleHubCompactChrome(
        context: context,
        state: state,
        l: l,
        roster: roster,
      );
      screenTitle = chrome.screenTitle;
      contextualActions = chrome.contextualActions;
      backPath = chrome.backPath;
      forceBackPath = chrome.forceBackPath;
      if (chrome.preferNavigatorPop) {
        onShellBack = () {
          if (context.canPop()) {
            context.pop();
          } else if (backPath != null) {
            context.go(backPath!);
          }
        };
      }
    }

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: peopleHubShellLocation(state),
      screenTitle: screenTitle,
      contextualActions: contextualActions,
      backPath: backPath,
      forceBackPath: forceBackPath,
      onBackPressed: onShellBack,
      child: body,
      floatingActionButton: showCompactFab
          ? FloatingActionButton.extended(
              key: const Key('people_hub_fab_add'),
              onPressed: () => context.push('/pc/people/new'),
              icon: const Icon(Icons.person_add_outlined),
              label: Text(l.peopleAddPerson),
            )
          : null,
    );
  }
}
