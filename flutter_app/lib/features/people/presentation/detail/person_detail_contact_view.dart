import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/people_providers.dart';
import '../../domain/entities/contact_detail.dart';
import '../../domain/entities/contact_summary.dart';
import '../../domain/entities/roster.dart';
import '../../domain/enums/contact_group.dart';
import '../widgets/contact_action_bar.dart';
import '../widgets/person_skeleton.dart';
import 'person_detail_header.dart';
import 'person_detail_shell.dart';
import 'person_detail_target.dart';
import 'tabs/person_detail_notes_tab.dart';
import 'tabs/person_detail_overview_tab.dart';
import 'tabs/person_detail_pets_access_tab.dart';
import 'tabs/person_detail_related_care_tab.dart';

class PersonDetailContactView extends ConsumerWidget {
  const PersonDetailContactView({
    super.key,
    required this.contactId,
    required this.embedded,
    required this.roster,
    this.memberTabsOnly = false,
  });

  final String contactId;
  final bool embedded;
  final Roster roster;
  final bool memberTabsOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final summary = ref.watch(personSummaryProvider(contactId));
    final detailAsync = ref.watch(personDetailProvider(contactId));

    return PersonDetailShell(
      embedded: embedded,
      personId: contactId,
      title: summary?.name ?? detailAsync.valueOrNull?.name,
      editAction: IconButton(
        tooltip: l.peopleEditPerson,
        onPressed: () => context.push('/pc/people/$contactId/edit'),
        icon: const Icon(Icons.edit_outlined),
      ),
      body: detailAsync.when(
        loading: () => _loadingBody(context, summary),
        error: (_, __) => Center(child: Text(l.peopleListLoadError)),
        data: (detail) {
          if (detail == null) {
            return Center(child: Text(l.peopleDetailNotFound));
          }
          return _loadedBody(context, l, summary, detail);
        },
      ),
    );
  }

  Widget _loadingBody(BuildContext context, ContactSummary? summary) {
    if (summary == null) {
      return const Center(child: PersonSkeleton());
    }
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: PersonDetailHeader.fromSummary(l, summary),
        ),
        const Expanded(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _loadedBody(
    BuildContext context,
    AppLocalizations l,
    ContactSummary? summary,
    ContactDetail detail,
  ) {
    final headerSummary = summary ?? detail.toSummary();
    final showRelated =
        !memberTabsOnly &&
        (headerSummary.group == ContactGroup.carer ||
            headerSummary.group == ContactGroup.professional);
    final showHouseholdNote = detail.directory.isHousehold;

    final tabs = <_TabSpec>[
      if (!memberTabsOnly)
        _TabSpec(
          id: 'overview',
          label: l.peopleDetailTabOverview,
          body: PersonDetailOverviewTab(detail: detail, summary: summary),
        ),
      _TabSpec(
        id: 'pets_access',
        label: l.peopleDetailTabPetsAccess,
        body: PersonDetailPetsAccessTab(
          contactId: contactId,
          pets: headerSummary.pets,
          access: headerSummary.access,
          rosterPetOptions: rosterPetOptions(roster),
        ),
      ),
      if (showRelated)
        _TabSpec(
          id: 'related_care',
          label: l.peopleDetailTabRelatedCare,
          body: PersonDetailRelatedCareTab(contactId: contactId),
        ),
      _TabSpec(
        id: 'notes',
        label: l.peopleDetailTabNotes,
        body: PersonDetailNotesTab(
          contactId: contactId,
          detail: detail,
          showHouseholdNote: showHouseholdNote,
        ),
      ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: PersonDetailHeader.fromDetail(l, detail),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ContactActionBar(
              phone: detail.phone,
              email: detail.email,
              address: detail.address,
              website: detail.website,
            ),
          ),
          TabBar(
            isScrollable: true,
            tabs: [
              for (final tab in tabs)
                Tab(
                  child: Semantics(
                    identifier: 'people_detail_tab_${tab.id}',
                    label: tab.label,
                    child: Text(tab.label),
                  ),
                ),
            ],
          ),
          Expanded(
            child: TabBarView(children: [for (final tab in tabs) tab.body]),
          ),
        ],
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({required this.id, required this.label, required this.body});

  final String id;
  final String label;
  final Widget body;
}
