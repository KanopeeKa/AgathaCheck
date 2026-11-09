import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/people_providers.dart';
import 'person_detail_contact_view.dart';
import 'person_detail_invite_view.dart';
import 'person_detail_member_view.dart';
import 'person_detail_target.dart';

class PersonDetailPage extends ConsumerWidget {
  const PersonDetailPage({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final rosterAsync = ref.watch(rosterProvider);

    return rosterAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(l.peopleListLoadError)),
      data: (roster) {
        final target = resolvePersonDetailTarget(roster, personId);
        if (target == null) {
          return Center(child: Text(l.peopleDetailNotFound));
        }
        return switch (target) {
          PersonDetailContactTarget() => PersonDetailContactView(
            contactId: target.contactId,
            roster: roster,
          ),
          PersonDetailHouseholdMemberTarget() => PersonDetailMemberView(
            target: target,
            roster: roster,
          ),
          PersonDetailPendingInviteTarget() => PersonDetailInviteView(
            target: target,
            roster: roster,
          ),
        };
      },
    );
  }
}
