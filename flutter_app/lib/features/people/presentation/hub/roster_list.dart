import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/widgets/collection_filter/collection_filter.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/people_providers.dart';
import '../../domain/entities/roster.dart';
import '../../domain/services/roster_search.dart';
import '../../domain/services/roster_sections.dart';
import '../widgets/person_skeleton.dart';
import 'hub_search_field.dart';
import 'people_hub_route.dart';
import 'people_roster_collection_filter.dart';
import 'roster_hub_query.dart';
import 'roster_list_sections.dart';
import 'roster_list_states.dart';

class RosterList extends ConsumerStatefulWidget {
  const RosterList({
    super.key,
    this.selectedPersonId,
    this.showWideHeaderActions = false,
  });

  final String? selectedPersonId;
  final bool showWideHeaderActions;

  @override
  ConsumerState<RosterList> createState() => _RosterListState();
}

class _RosterListState extends ConsumerState<RosterList> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = GoRouterState.of(context);
    final hubQuery = RosterHubQuery.fromUri(state.uri);
    final rosterAsync = ref.watch(rosterProvider);

    return rosterAsync.when(
      loading: () => ListView(
        padding: const EdgeInsets.all(16),
        children: const [PersonSkeleton(), PersonSkeleton(), PersonSkeleton()],
      ),
      error: (_, __) => RosterErrorState(
        onRetry: () => ref.read(rosterProvider.notifier).refresh(),
      ),
      data: (roster) {
        final dimensions = peopleRosterFilterDimensions(l, roster);
        final sections = _visibleSections(roster, hubQuery);
        final invites = roster.pendingInvites
            .where((i) => rosterInviteMatchesQuery(i, hubQuery))
            .toList();
        final isEmpty = sections.isEmpty && invites.isEmpty;

        return RefreshIndicator(
          onRefresh: () => ref.read(rosterProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            children: [
              if (widget.showWideHeaderActions) _WideHeader(l: l),
              HubSearchField(
                query: hubQuery.searchQuery,
                onQueryChanged: (value) =>
                    _syncQuery(context, hubQuery.copyWithSearch(value.trim())),
              ),
              const SizedBox(height: 8),
              CollectionFilterBar(
                dimensions: dimensions,
                selections: hubQuery.filterSelections,
                primaryDimensionIds: PeopleRosterCollectionFilterIds.primary,
                onSelectionsChanged: (selections) => _syncQuery(
                  context,
                  RosterHubQuery(
                    searchQuery: hubQuery.searchQuery,
                    filterSelections: selections,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (isEmpty)
                RosterEmptyState(onAdd: () => context.push('/pc/people/new'))
              else ...[
                for (final section in sections)
                  RosterSectionBlock(
                    section: section,
                    hubQuery: hubQuery,
                    onSelect: (id) => _selectPerson(context, id, hubQuery),
                  ),
                if (invites.isNotEmpty &&
                    rosterSectionVisibleForFilters(
                      RosterSectionKind.pendingInvites,
                      hubQuery,
                    ))
                  PendingInvitesRosterSection(invites: invites),
              ],
            ],
          ),
        );
      },
    );
  }

  List<RosterSection> _visibleSections(Roster roster, RosterHubQuery query) {
    final built = buildRosterSections(roster);
    final out = <RosterSection>[];
    for (final section in built) {
      if (!rosterSectionVisibleForFilters(section.kind, query)) continue;
      if (section.kind == RosterSectionKind.inactive) {
        final entries = section.entries
            .where((e) => rosterContactMatchesFilters(e, query))
            .toList();
        if (entries.isEmpty) continue;
        out.add(
          RosterSection(
            kind: section.kind,
            titleKey: section.titleKey,
            entries: entries,
          ),
        );
        continue;
      }
      if (section.kind == RosterSectionKind.household) {
        out.add(section);
        continue;
      }
      final entries = searchContacts(
        section.entries
            .where((e) => rosterContactMatchesFilters(e, query))
            .toList(),
        query.searchQuery,
      );
      if (entries.isEmpty) continue;
      out.add(
        RosterSection(
          kind: section.kind,
          household: section.household,
          titleKey: section.titleKey,
          entries: entries,
        ),
      );
    }
    return out;
  }

  void _syncQuery(BuildContext context, RosterHubQuery query) {
    final state = GoRouterState.of(context);
    final personId = peoplePersonIdFromState(state);
    final params = query.toQueryParameters(base: state.uri.queryParameters);
    context.go(
      peopleHubNavigatePath(personId: personId, queryParameters: params),
    );
  }

  void _selectPerson(BuildContext context, String id, RosterHubQuery query) {
    final params = query.toQueryParameters();
    context.go(peopleHubNavigatePath(personId: id, queryParameters: params));
  }
}

extension on RosterHubQuery {
  RosterHubQuery copyWithSearch(String searchQuery) {
    return RosterHubQuery(
      searchQuery: searchQuery,
      filterSelections: filterSelections,
    );
  }
}

class _WideHeader extends StatelessWidget {
  const _WideHeader({required this.l});

  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.peoplePageTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          FilledButton.icon(
            key: const Key('people_hub_add_person'),
            onPressed: () => context.push('/pc/people/new'),
            icon: const Icon(Icons.person_add_outlined),
            label: Text(l.peopleAddPerson),
          ),
        ],
      ),
    );
  }
}
