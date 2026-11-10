import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/async_state/async_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/people_providers.dart';
import 'person_detail_contact_view.dart';
import 'person_detail_invite_view.dart';
import 'person_detail_member_view.dart';
import 'person_detail_target.dart';

class PersonDetailPage extends ConsumerWidget {
  const PersonDetailPage({super.key, required this.personId});

  final String personId;

  static Widget _unavailablePersonBody(
    BuildContext context,
    AppLocalizations l,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AsyncErrorState(title: l.peopleDetailNotFound, detail: null),
        TextButton(
          key: const Key('person_detail_back_to_contacts'),
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => AsyncErrorState(
        title: l.peopleListLoadError,
        onRetry: () => ref.read(rosterProvider.notifier).refresh(),
        retryKey: const Key('person_detail_roster_retry'),
      ),
      data: (roster) {
        final target = resolvePersonDetailTarget(roster, personId);
        if (target == null) {
          return _unavailablePersonBody(context, l);
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
