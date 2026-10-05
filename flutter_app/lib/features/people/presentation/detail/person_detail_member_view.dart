import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/contact_summary.dart';
import '../../domain/entities/roster.dart';
import '../../domain/enums/relationship_kind.dart';
import 'person_detail_contact_view.dart';
import 'person_detail_header.dart';
import 'person_detail_shell.dart';
import 'person_detail_target.dart';
import 'tabs/person_detail_pets_access_tab.dart';

class PersonDetailMemberView extends ConsumerWidget {
  const PersonDetailMemberView({
    super.key,
    required this.target,
    required this.embedded,
    required this.roster,
  });

  final PersonDetailHouseholdMemberTarget target;
  final bool embedded;
  final Roster roster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final contact = target.contact;

    if (contact != null) {
      return PersonDetailContactView(
        contactId: contact.id,
        embedded: embedded,
        roster: roster,
        memberTabsOnly: true,
      );
    }

    return PersonDetailShell(
      embedded: embedded,
      personId: target.member.userId,
      title: target.member.displayName,
      body: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: PersonDetailHeader.forHouseholdMember(
                l,
                member: target.member,
              ),
            ),
            TabBar(
              tabs: [
                Tab(
                  child: Semantics(
                    identifier: 'people_detail_tab_pets_access',
                    label: l.peopleDetailTabPetsAccess,
                    child: Text(l.peopleDetailTabPetsAccess),
                  ),
                ),
                Tab(
                  child: Semantics(
                    identifier: 'people_detail_tab_notes',
                    label: l.peopleDetailTabNotes,
                    child: Text(l.peopleDetailTabNotes),
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  PersonDetailPetsAccessTab(
                    contactId: target.member.userId,
                    pets: _memberPetLinks(target, roster),
                    access: null,
                    rosterPetOptions: rosterPetOptions(roster),
                    allowLink: false,
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l.peopleContactInfoEmpty,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ContactPetLink> _memberPetLinks(
    PersonDetailHouseholdMemberTarget target,
    Roster roster,
  ) {
    final links = <ContactPetLink>[];
    for (final petId in target.member.ownsPetIds) {
      links.add(
        ContactPetLink(
          petId: petId,
          petName: rosterPetName(roster, petId) ?? petId,
          relationshipKind: RelationshipKind.other,
        ),
      );
    }
    for (final petId in target.member.sharesPetIds) {
      if (target.member.ownsPetIds.contains(petId)) continue;
      links.add(
        ContactPetLink(
          petId: petId,
          petName: rosterPetName(roster, petId) ?? petId,
          relationshipKind: RelationshipKind.other,
        ),
      );
    }
    return links;
  }
}
