import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/role_pill.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pet_people.dart';
import '../../domain/entities/pet_people_grouped.dart';
import '../../domain/entities/roster.dart';
import '../../domain/enums/contact_kind.dart';
import '../../domain/enums/contact_role.dart';
import '../../domain/enums/relationship_kind.dart';
import '../detail/person_detail_target.dart';
import '../households/household_tier_labels.dart';
import '../labels/people_labels.dart';
import 'widgets/people_group_box.dart';
import 'widgets/person_row.dart';

List<PeopleGroupSection> buildPetPeopleGroupSections({
  required BuildContext context,
  required AppLocalizations l,
  required PetPeople people,
  required PetPeopleGroupedSection grouped,
  required bool rosterReady,
  Roster? roster,
  required String? viewerUserId,
}) {
  final sections = <PeopleGroupSection>[];

  sections.add(
    _vetsSection(context, l, people, grouped, rosterReady, roster, viewerUserId),
  );

  final emergency = grouped.emergencyContacts;
  if (emergency != null && emergency.isNotEmpty) {
    sections.add(
      PeopleGroupSection(
        heading: l.peopleGroupEmergencyContacts,
        rows: emergency
            .map(
              (row) => _contactRow(
                context: context,
                l: l,
                people: people,
                row: row,
                rosterReady: rosterReady,
                roster: roster,
                viewerUserId: viewerUserId,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  sections.add(
    PeopleGroupSection(
      heading: l.peopleGroupAtHome,
      rows: grouped.atHome.rows
          .map(
            (member) => _memberRow(
              context: context,
              l: l,
              people: people,
              member: member,
              rosterReady: rosterReady,
              roster: roster,
              viewerUserId: viewerUserId,
            ),
          )
          .toList(growable: false),
    ),
  );

  final carers = grouped.trustedCarers;
  if (carers != null && carers.isNotEmpty) {
    sections.add(
      PeopleGroupSection(
        heading: l.peopleGroupCarers,
        rows: carers
            .map(
              (row) => _contactRow(
                context: context,
                l: l,
                people: people,
                row: row,
                rosterReady: rosterReady,
                roster: roster,
                viewerUserId: viewerUserId,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  final professionals = grouped.otherProfessionals;
  if (professionals != null && professionals.isNotEmpty) {
    sections.add(
      PeopleGroupSection(
        heading: l.peopleGroupPetProfessionals,
        rows: professionals
            .map(
              (row) => _contactRow(
                context: context,
                l: l,
                people: people,
                row: row,
                rosterReady: rosterReady,
                roster: roster,
                viewerUserId: viewerUserId,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  return sections;
}

PeopleGroupSection _vetsSection(
  BuildContext context,
  AppLocalizations l,
  PetPeople people,
  PetPeopleGroupedSection grouped,
  bool rosterReady,
  Roster? roster,
  String? viewerUserId,
) {
  final rows = <Widget>[];
  for (final row in grouped.vets.rows) {
    rows.add(
      _contactRow(
        context: context,
        l: l,
        people: people,
        row: row,
        rosterReady: rosterReady,
        roster: roster,
        viewerUserId: viewerUserId,
      ),
    );
  }
  if (!grouped.vets.hasPrimaryVet) {
    rows.add(
      PersonRow(
        name: l.peoplePetAddPrimaryVet(people.petName),
        stableId: 'primary_vet_placeholder',
        tappable: false,
        pills: [
          RolePill(
            label: RelationshipKind.primaryVet.label(l),
            leadingIcon: Icons.star_rounded,
          ),
        ],
      ),
    );
  }
  return PeopleGroupSection(heading: l.peopleGroupVets, rows: rows);
}

Widget _contactRow({
  required BuildContext context,
  required AppLocalizations l,
  required PetPeople people,
  required PetPeopleGroupedContactRow row,
  required bool rosterReady,
  Roster? roster,
  required String? viewerUserId,
}) {
  final onTap = _contactTapHandler(
    context: context,
    people: people,
    contactId: row.contactId,
    rosterReady: rosterReady,
    roster: roster,
  );
  return PersonRow(
    name: row.name,
    stableId: row.contactId,
    phone: row.phone,
    semanticsCallId: _callSemanticsId(row),
    photoUrl: null,
    contactKind: ContactKind.fromWire(row.contactKind),
    pills: _slotPills(l, row.slotKinds),
    subtitle: row.slotKinds.isEmpty
        ? contactRolesLine(l, ContactRole.fromWireList(row.contactRoles))
        : null,
    tappable: onTap != null,
    onTap: onTap,
  );
}

Widget _memberRow({
  required BuildContext context,
  required AppLocalizations l,
  required PetPeople people,
  required PetPeopleGroupedMemberRow member,
  required bool rosterReady,
  Roster? roster,
  required String? viewerUserId,
}) {
  final isViewer = viewerUserId != null && member.userId == viewerUserId;
  final subtitle = member.isOwner
      ? l.peopleParentOf(people.petName)
      : householdTierLabel(
          l,
          member.tier,
          organiser: member.isOrganiser,
        );
  final onTap = isViewer
      ? null
      : _memberTapHandler(
          context: context,
          people: people,
          userId: member.userId,
          rosterReady: rosterReady,
          roster: roster,
        );
  return PersonRow(
    name: member.displayName,
    stableId: member.userId,
    photoUrl: member.photoUrl,
    subtitle: subtitle,
    tappable: onTap != null,
    onTap: onTap,
  );
}

List<RolePill> _slotPills(AppLocalizations l, List<RelationshipKind> kinds) {
  return kinds
      .map(
        (kind) => RolePill(
          label: kind.label(l),
          leadingIcon: kind == RelationshipKind.primaryVet
              ? Icons.star_rounded
              : null,
        ),
      )
      .toList(growable: false);
}

String? _callSemanticsId(PetPeopleGroupedContactRow row) {
  if (row.slotKinds.contains(RelationshipKind.primaryVet)) {
    return 'pet_emergency_call_primary_vet';
  }
  if (row.slotKinds.contains(RelationshipKind.outOfHoursVet)) {
    return 'pet_emergency_call_ooh_vet';
  }
  if (row.slotKinds.contains(RelationshipKind.emergencyContact)) {
    return 'pet_emergency_call_${row.contactId}';
  }
  return 'pet_people_call_${row.contactId}';
}

VoidCallback? _contactTapHandler({
  required BuildContext context,
  required PetPeople people,
  required String contactId,
  required bool rosterReady,
  Roster? roster,
}) {
  if (people.scope == 'handover') {
    return () => context.push('/pc/people/$contactId');
  }
  if (!rosterReady || roster == null) return null;
  final target = resolvePersonDetailTarget(roster, contactId);
  if (target == null) return null;
  return () => context.push('/pc/people/$contactId');
}

VoidCallback? _memberTapHandler({
  required BuildContext context,
  required PetPeople people,
  required String userId,
  required bool rosterReady,
  Roster? roster,
}) {
  if (people.scope == 'handover') return null;
  if (!rosterReady || roster == null) return null;
  final target = resolvePersonDetailTarget(roster, userId);
  if (target == null) return null;
  return () => context.push('/pc/people/$userId');
}
