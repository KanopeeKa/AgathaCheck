import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/async_state/async_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/people_providers.dart';
import '../detail/person_detail_target.dart';
import '../hub/people_hub_shell_chrome.dart';
import 'person_edit_contact_form.dart';
import 'person_edit_invite_form.dart';
import 'person_edit_member_form.dart';

class PersonEditPage extends ConsumerWidget {
  const PersonEditPage({super.key, required this.personId});

  final String personId;

  static Widget _unavailableBody(BuildContext context, AppLocalizations l) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AsyncErrorState(title: l.peopleDetailNotFound, detail: null),
        TextButton(
          key: const Key('person_edit_back_to_contacts'),
          onPressed: () => context.go('/pc/people'),
          child: Text(l.peopleBackToContacts),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final rosterAsync = ref.watch(rosterProvider);

    return rosterAsync.when(
      loading: () => peopleHubPaneScaffold(
        context: context,
        title: Text(l.peopleEditPerson),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => peopleHubPaneScaffold(
        context: context,
        title: Text(l.peopleEditPerson),
        body: AsyncErrorState(
          title: l.peopleListLoadError,
          onRetry: () => ref.read(rosterProvider.notifier).refresh(),
          retryKey: const Key('person_edit_roster_retry'),
        ),
      ),
      data: (roster) {
        final target = resolvePersonDetailTarget(roster, personId);
        if (target == null) {
          return peopleHubPaneScaffold(
            context: context,
            title: Text(l.peopleEditPerson),
            body: _unavailableBody(context, l),
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
