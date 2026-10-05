import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/people_providers.dart';
import '../detail/person_detail_target.dart';
import 'person_edit_contact_form.dart';
import 'person_edit_invite_form.dart';
import 'person_edit_member_form.dart';

class PersonEditPage extends ConsumerWidget {
  const PersonEditPage({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final rosterAsync = ref.watch(rosterProvider);

    return rosterAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l.peopleEditPerson)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text(l.peopleEditPerson)),
        body: Center(child: Text(l.peopleListLoadError)),
      ),
      data: (roster) {
        final target = resolvePersonDetailTarget(roster, personId);
        if (target == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l.peopleEditPerson)),
            body: Center(child: Text(l.peopleDetailNotFound)),
          );
        }
        return switch (target) {
          PersonDetailContactTarget() => PersonEditContactForm(
            contactId: target.contactId,
            roster: roster,
          ),
          PersonDetailHouseholdMemberTarget() => PersonEditMemberForm(
            household: target.household,
            memberUserId: target.member.userId,
            memberName: target.member.displayName,
          ),
          PersonDetailPendingInviteTarget() => PersonEditInviteForm(
            invite: target.invite,
            householdId: target.invite.householdId ?? '',
          ),
        };
      },
    );
  }
}
