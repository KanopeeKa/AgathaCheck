import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../experience/domain/entities/app_experience.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../../sharing/domain/entities/household_summary.dart';
import '../../../sharing/presentation/providers/household_providers.dart';
import '../../domain/entities/people_contact.dart';
import '../providers/people_providers.dart';

enum PeopleListFilter { all, household, carers, professionals }

PeopleListFilter peopleListFilterFromQuery(String? raw) {
  switch (raw) {
    case 'household':
      return PeopleListFilter.household;
    case 'carers':
      return PeopleListFilter.carers;
    case 'professionals':
      return PeopleListFilter.professionals;
    default:
      return PeopleListFilter.all;
  }
}

class PeopleListScreen extends ConsumerStatefulWidget {
  const PeopleListScreen({super.key});

  @override
  ConsumerState<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends ConsumerState<PeopleListScreen> {
  String _searchQuery = '';
  PeopleListFilter _filter = PeopleListFilter.all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final filterParam = GoRouterState.of(context).uri.queryParameters['filter'];
    _filter = peopleListFilterFromQuery(filterParam);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final asyncContacts = ref.watch(peopleContactsProvider);
    final householdsAsync = ref.watch(householdListProvider);

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: '/pc/people',
      screenTitle: l.peoplePageTitle,
      child: asyncContacts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.peopleListLoadError)),
        data: (contacts) {
          final households = householdsAsync.valueOrNull ?? const <HouseholdSummary>[];
          final filtered = _filterContacts(contacts, _searchQuery);
          final pros = filtered.where((c) => c.isProfessional).toList();
          final prosIds = pros.map((c) => c.id).toSet();
          final carers = filtered.where((c) => !prosIds.contains(c.id)).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(peopleContactsProvider.notifier).refresh();
              ref.invalidate(householdListProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Semantics(
                  label: l.peopleSearchHint,
                  child: TextField(
                    key: const Key('people_list_search'),
                    decoration: InputDecoration(
                      hintText: l.peopleSearchHint,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value.trim()),
                  ),
                ),
                const SizedBox(height: 12),
                _FilterChips(
                  selected: _filter,
                  onSelected: (f) => setState(() => _filter = f),
                ),
                const SizedBox(height: 16),
                ..._buildSections(
                  l: l,
                  filter: _filter,
                  households: households,
                  carers: carers,
                  pros: pros,
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>('/pc/people/new');
          if (created == true) {
            ref.invalidate(peopleContactsProvider);
          }
        },
        icon: const Icon(Icons.person_add_outlined),
        label: Text(l.peopleAddPerson),
      ),
    );
  }

  static List<PeopleContact> _filterContacts(
    List<PeopleContact> contacts,
    String query,
  ) {
    if (query.isEmpty) return contacts;
    final lower = query.toLowerCase();
    return contacts
        .where((c) => c.name.toLowerCase().contains(lower))
        .toList();
  }

  List<Widget> _buildSections({
    required AppLocalizations l,
    required PeopleListFilter filter,
    required List<HouseholdSummary> households,
    required List<PeopleContact> carers,
    required List<PeopleContact> pros,
  }) {
    final children = <Widget>[];

    if (filter == PeopleListFilter.all || filter == PeopleListFilter.household) {
      for (final household in households) {
        children.add(
          _Section(
            key: Key('people_household_${household.id}'),
            title: household.name,
            contacts: const [],
            empty: l.peopleHouseholdDirectoryEmpty,
          ),
        );
        children.add(const SizedBox(height: 24));
      }
    }

    if (filter == PeopleListFilter.all || filter == PeopleListFilter.carers) {
      children.add(
        _Section(
          title: l.peopleTrustedCarersSection,
          contacts: carers,
          empty: l.peopleEmptyCarers,
        ),
      );
      children.add(const SizedBox(height: 24));
    }

    if (filter == PeopleListFilter.all || filter == PeopleListFilter.professionals) {
      children.add(
        _Section(
          title: l.peopleProfessionalsSection,
          contacts: pros,
          empty: l.peopleEmptyProfessionals,
        ),
      );
    }

    if (children.isEmpty) {
      children.add(Text(l.peopleEmptyCarers));
    }

    return children;
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onSelected,
  });

  final PeopleListFilter selected;
  final ValueChanged<PeopleListFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _chip(l.peopleFilterAll, PeopleListFilter.all),
        _chip(l.peopleFilterHousehold, PeopleListFilter.household),
        _chip(l.peopleFilterCarers, PeopleListFilter.carers),
        _chip(l.peopleFilterProfessionals, PeopleListFilter.professionals),
      ],
    );
  }

  Widget _chip(String label, PeopleListFilter value) {
    return FilterChip(
      key: Key('people_filter_${value.name}'),
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => onSelected(value),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.title,
    required this.contacts,
    required this.empty,
  });

  final String title;
  final List<PeopleContact> contacts;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (contacts.isEmpty)
          Text(empty, style: Theme.of(context).textTheme.bodyMedium)
        else
          ...contacts.map(
            (c) => ListTile(
              key: Key('people_contact_${c.id}'),
              title: Text(c.name),
              subtitle: Text(c.roles.isEmpty ? c.kind : c.roles.join(' · ')),
              leading: CircleAvatar(
                child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?'),
              ),
            ),
          ),
      ],
    );
  }
}
